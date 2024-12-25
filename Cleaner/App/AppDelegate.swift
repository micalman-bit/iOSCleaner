//
//  AppDelegate.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

// MARK: - AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        startViewControllerIfNeeded()
        
        return true
    }

    // MARK: - Private Methods

    private func startViewControllerIfNeeded() {
        guard window == nil else { return }
        window = UIWindow()
        UserDefaultsService.isPassOnboarding = true// ???
        ApplicationRouter.installStartViewController(into: window)
        window?.makeKeyAndVisible()
    }
}

