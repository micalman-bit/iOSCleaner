//
//  PresentationController.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

// MARK: - PresentationControllerDelegate

protocol PresentationControllerDelegate: UIAdaptivePresentationControllerDelegate {
    /// Determines the `UIView`, by tapping on which the presented screen will be dismissed
    func backgroundView(for presentationController: UIPresentationController) -> UIView?

    /// Determines the possibility of a swipe to close the displayed screen
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController,
        withInteractionIn view: UIView?
    ) -> Bool

    /// Informs about the closing of the presented screen
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
}

// MARK: - PresentationController

/// A controller that obscures the background and adds swipe and tap gestures to hide the screen being modally presented
final class PresentationController: UIPresentationController {
    // MARK: - Constants

    private enum Constants {
        static let animationDuration = 0.25
        static let elasticThreshold: CGFloat = 80
        static let dismissThreshold: CGFloat = 120
        static let translationFactor: CGFloat = 0.5
        static let backgroundColor = UIColor.white.withAlphaComponent(0.4) // TODO: - MAYBE FIX IT
    }

    // MARK: - Private Properties

    private var backgroundView = UIView()
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var tapGestureRecognizer: UITapGestureRecognizer?

    // MARK: - UIPresentationController

    override func presentationTransitionWillBegin() {
        guard
            let containerView = containerView,
            let window = containerView.window
        else { return }

        containerView.insertSubview(backgroundView, aboveSubview: presentedViewController.view)
        backgroundView.backgroundColor = Constants.backgroundColor
        backgroundView.alpha = 0
//        backgroundView.snp.makeConstraints {
//            $0.edges.equalTo(window)
//        }
        presentedViewController.transitionCoordinator?.animate { [weak self] _ in
            self?.backgroundView.alpha = 1
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.cancelsTouchesInView = false
        presentedViewController.view.addGestureRecognizer(panGestureRecognizer)

        self.panGestureRecognizer = panGestureRecognizer

        guard
            let presentationDelegate = delegate as? PresentationControllerDelegate,
            let backgroundView = presentationDelegate.backgroundView(for: self)
        else { return }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerAction))
        tapGestureRecognizer.delegate = self
        backgroundView.addGestureRecognizer(tapGestureRecognizer)

        self.tapGestureRecognizer = tapGestureRecognizer
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [weak self] _ in
                self?.backgroundView.alpha = 0
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                (self.delegate as? PresentationControllerDelegate)?.presentationControllerDidDismiss(self)
                self.backgroundView.removeFromSuperview()
            }
        )
    }

    // MARK: - Gesture recognizer actions

    @objc private func tapGestureRecognizerAction(gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer == tapGestureRecognizer else { return }
        presentedViewController.dismiss(animated: true)
    }

    @objc private func panGestureRecognizerAction(gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer == panGestureRecognizer else { return }

        switch gestureRecognizer.state {
        case .began:
            gestureRecognizer.setTranslation(.zero, in: containerView)
        case .changed:
            let translation = gestureRecognizer.translation(in: presentedView)
            updatePresentedViewForTranslation(inVerticalDirection: translation.y)
        case .ended:
            UIView.animate(withDuration: Constants.animationDuration) {
                self.presentedView?.transform = .identity
            }
        default:
            break
        }
    }

    private func updatePresentedViewForTranslation(inVerticalDirection translation: CGFloat) {
        guard translation >= 0 else { return }

        let translationForModal: CGFloat
        if translation >= Constants.elasticThreshold {
            let frictionLength = translation - Constants.elasticThreshold
            let frictionTranslation = 30 * atan(frictionLength / 120) + frictionLength / 10
            translationForModal = frictionTranslation + (Constants.elasticThreshold * Constants.translationFactor)
        } else {
            translationForModal = translation * Constants.translationFactor
        }

        presentedView?.transform = CGAffineTransform(translationX: 0, y: translationForModal)

        if translation >= Constants.dismissThreshold {
            presentedViewController.dismiss(animated: true)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer == panGestureRecognizer, otherGestureRecognizer == tapGestureRecognizer {
            return true
        }
        guard gestureRecognizer == panGestureRecognizer else {
            return false
        }
        if let presentationControllerDelegate = delegate as? PresentationControllerDelegate {
            return presentationControllerDelegate.presentationControllerShouldDismiss(
                self,
                withInteractionIn: otherGestureRecognizer.view
            )
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer == tapGestureRecognizer,
              let tappedView = touch.view,
              let presentationControllerDelegate = delegate as? PresentationControllerDelegate,
              let backgroundView = presentationControllerDelegate.backgroundView(for: self) else {
            return true
        }
        return tappedView == backgroundView
    }
}
