//
//  ApplicationRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

private let SCREEN_WIDTH = Int(UIScreen.main.bounds.size.width)
private let SCREEN_HEIGHT = Int(UIScreen.main.bounds.size.height)
private let SCREEN_MAX_LENGTH = Int(max(SCREEN_WIDTH, SCREEN_HEIGHT))
let isSmallPhone = SCREEN_MAX_LENGTH == 568
let isBorderless = UIScreen.main.nativeBounds.height > 1_700 && UIScreen.main.nativeBounds.height != 1_920

extension UIApplication {
    /// Возвращает текущее ключевое окно
    static var currentKeyWindow: UIWindow? {
        return shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - ApplicationRouter

final class ApplicationRouter: DefaultRouter {
    /// StartViewController
    private static var rootViewController: UINavigationController? {
        return UIApplication.currentKeyWindow?.rootViewController as? UINavigationController
    }

    /// Делает StartViewController главным в window
    /// - Parameter window: Окно приложения
    static func installStartViewController(into window: UIWindow?) {
        guard window != nil else { return }
        let viewController = HomeAssembly.openHome()
        let navigationViewController = CleanerNavigationController(rootViewController: viewController)
        navigationViewController.navigationBar.isHidden = true

        window?.rootViewController = navigationViewController
    }
}

