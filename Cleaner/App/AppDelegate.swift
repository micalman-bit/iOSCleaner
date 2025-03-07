//
//  AppDelegate.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit
import FirebaseCore
import Adapty

// MARK: - AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        let configurationBuilder = Adapty.Configuration
            .builder(withAPIKey: "public_live_tZwRABh3.xwY0GTFVSUTolpPUEKOQ")
            .with(observerMode: false)
            .with(customerUserId: "general")
            .with(idfaCollectionDisabled: false)
            .with(ipAddressCollectionDisabled: false)

        Adapty.activate(with: configurationBuilder) { error in
            if let error = error {
                print("Adapty activation error: \(error)")
            } else {
                print("Adapty is activated: \(Adapty.isActivated)")
            }
        }

        Task {
            await fetchPaywall()
        }

        startViewControllerIfNeeded()
        
        return true
    }

    func fetchPaywall() async {
        do {
            let paywall = try await Adapty.getPaywall(placementId: "general")
            print("Paywall received: \(paywall)")
        } catch {
            print("Failed to fetch paywall: \(error)")
        }
    }

    // MARK: - Private Methods

    private func startViewControllerIfNeeded() {
        guard window == nil else { return }
        window = UIWindow()
        ApplicationRouter.installStartViewController(into: window)
        window?.makeKeyAndVisible()
    }
}

