//
//  OnboardingViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import Foundation

final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Private Properties

    private let service: OnboardingService
    private let router: OnboardingRouter

    // MARK: - Init

    init(
        service: OnboardingService,
        router: OnboardingRouter
    ) {
        self.service = service
        self.router = router
    }
    
    func openPaywall() {
        UserDefaultsService.isPassOnboarding = true
        router.openPaywall()
    }
}
