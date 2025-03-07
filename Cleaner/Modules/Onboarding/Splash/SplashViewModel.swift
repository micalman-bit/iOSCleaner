//
//  SplashViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 04.12.2024.
//

import Foundation
import AdSupport
import AppTrackingTransparency
import UIKit

final class SplashViewModel: ObservableObject {
    
    // MARK: - Private Properties
    private let router: SplashRouter
    
    // Флаг для показа алерта в SwiftUI
    @Published var showTrackingAlert: Bool = false
    
    init(router: SplashRouter) {
        self.router = router
    }
    
    // MARK: - Public Method
    func requestTrackingPermission(completion: @escaping () -> Void) {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Tracking authorized")
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier
                    print("IDFA: \(idfa)")
                    completion()
                    
                case .denied, .notDetermined, .restricted:
                    print("❌ Tracking not authorized: \(status)")
                    self.showTrackingAlert = true
                    
                @unknown default:
                    print("⚠️ Unknown tracking status")
                    self.showTrackingAlert = true
                }
            }
        }
    }
    
    func openNextScreen() {
        router.openOnboarding()
        if UserDefaultsService.isPassOnboarding {
            if UserDefaultsService.isHaveSubscribe {
                 router.openHome()
            } else {
                 router.openHome()
//                 router.openPaywall()
            }
        } else {
             router.openOnboarding()
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
