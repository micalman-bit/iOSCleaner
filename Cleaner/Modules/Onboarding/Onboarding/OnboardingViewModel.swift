//
//  OnboardingViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import Foundation

final class OnboardingViewModel: ObservableObject {
    
    /// URL для открытия во встроенном WebView
    @Published var selectedURL: URL? = nil

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
    
    func didTapTermsOfUse() {
        if let url = URL(string: "https://weareadmire.com/tc") {
            selectedURL = url
        }
    }
    
    func didTapPrivacyPolicy() {
        if let url = URL(string: "https://weareadmire.com/pp") {
            selectedURL = url
        }
    }

    func openPaywall() {
        UserDefaultsService.isPassOnboarding = true
        router.openHome()
//        router.openPaywall()
    }
}
