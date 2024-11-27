//
//  DefaultRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI
import UIKit

// MARK: - DefaultRouter

protocol DefaultRouter {
    func push(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool
    )
    func push(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)?
    )
    func present(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        modalPresentationStyle: UIModalPresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    )
    func presentBottom(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)?
    )
    func showWebView(on currentViewController: UIViewController, url: URL)
    func dismissToAuth()
}

extension DefaultRouter {
    func push<T: View>(
        _ view: T,
        on currentViewController: UIViewController,
        animated: Bool = true
    ) {
        guard let navigationController = currentViewController.navigationController else { return }

        let hostingController = UIHostingController(rootView: view)

        navigationController.pushViewController(
            hostingController,
            animated: animated
        )
    }

    func push(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool = true
    ) {
        guard let navigationController = currentViewController.navigationController else { return }

        navigationController.pushViewController(
            viewController,
            animated: animated
        )
    }

    func push(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)?
    ) {
        guard let navigationController = currentViewController.navigationController else { return }

        navigationController.pushViewController(
            viewController,
            animated: animated
//            completion: completion
        )
    }

    func present(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        viewController.modalPresentationStyle = modalPresentationStyle

        currentViewController.modalPresentationStyle = modalPresentationStyle
        currentViewController.present(
            viewController,
            animated: animated,
            completion: completion
        )
    }

    func presentBottom(
        _ viewController: UIViewController,
        on currentViewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        var transitionDelegate: BottomTransition? = BottomTransition()
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = transitionDelegate

        let parent = currentViewController.presentedViewController ?? currentViewController
        parent.present(viewController, animated: animated) {
            // This is necessary so that the transitionDelegate isn't released before the animation starts
            transitionDelegate = nil
            completion?()
        }
    }

    func showActionSheet(
//        on currentViewController: UIViewController,
//        with viewModels: [ActionSheetViewModel],
//        cancelButtonTitle: String?
    ) {
//        let viewController = ActionSheetViewController(viewModels: viewModels, cancelButtonTitle: cancelButtonTitle)
//        presentBottom(viewController, on: currentViewController)
    }

    func showWebView(on currentViewController: UIViewController, url: URL) {
//        let controller = SFSafariViewController(url: url)
//        present(controller, on: currentViewController)
    }

    func dismissToAuth() {
//        UniversalLinkManager.shared.delegate = nil
        UIApplication.currentKeyWindow?.rootViewController?.dismiss(animated: true)
    }
}
