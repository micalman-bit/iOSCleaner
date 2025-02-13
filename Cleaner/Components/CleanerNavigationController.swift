//
//  CleanerNavigationController.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

final class CleanerNavigationController: UINavigationController {
    // MARK: - UI

    lazy var errorHeaderView: UIView = {
        let errorView = UIView()
        errorView.backgroundColor = .red

        view.addSubview(errorView)

        errorView.frame = CGRect(x: 0, y: isBorderless ? -64 : -44, width: view.frame.width, height: isBorderless ? 64 : 44)
        return errorView
    }()

    /// Везде стандартно прячется навигация, а также выставляется цвет статус бара
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return currentStatusBarStyle
    }

    var currentStatusBarStyle: UIStatusBarStyle = .default {
        didSet {
            UIView.animate(withDuration: 0.5) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = errorHeaderView
        currentStatusBarStyle = .default
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationBar.isHidden = true
        interactivePopGestureRecognizer?.isEnabled = false
        title = nil
    }

    // MARK: - Functions

    func showError() {
        UIView.animate(withDuration: 0.2) {
            self.errorHeaderView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: isBorderless ? 64 : 44)
        } completion: { _ in
            self.currentStatusBarStyle = .lightContent
        }
    }

    func hideError() {
        UIView.animate(withDuration: 0.2) {
            self.errorHeaderView.frame = CGRect(x: 0, y: isBorderless ? -64 : -44, width: self.view.frame.width, height: isBorderless ? 64 : 44)
        } completion: { _ in
            self.currentStatusBarStyle = .default
        }
    }

    // MARK: - Actions

    deinit {
    }
}

extension CleanerNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
