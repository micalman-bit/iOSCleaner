//
//  BottomTransition.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

/// Transition between screens used when displaying modal screens
final class BottomTransition: NSObject, UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    func presentationController(
        forPresented presentedViewController: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = PresentationController(
            presentedViewController: presentedViewController,
            presenting: presenting
        )
        if let presentationControllerDelegate = presentedViewController as? PresentationControllerDelegate {
            presentationController.delegate = presentationControllerDelegate
        }
        return presentationController
    }
}
