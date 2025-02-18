//
//  SplashViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 04.12.2024.
//

import Foundation
import AdSupport
import AppTrackingTransparency

final class SplashViewModel: ObservableObject {
    
    // MARK: - Private Properties

    private let router: SplashRouter

    init(
        router: SplashRouter
    ) {
        self.router = router
    }
    
    // MARK: - Public Method

    func requestTrackingPermission(completion: @escaping () -> Void) {
        // Запрос на разрешение
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func openNextScreen() {
        if UserDefaultsService.isPassOnboarding {
            if UserDefaultsService.isHaveSubscribe {
                router.openHome()
            } else {
                router.openHome()
//                router.openPaywal()
            }
        } else {
            router.openOnboarding()
        }
    }
}
