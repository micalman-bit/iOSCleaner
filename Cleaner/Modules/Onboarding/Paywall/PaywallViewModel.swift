//
//  PaywallViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import SwiftUI

final class PaywallViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                isSelectWeekPlan = true
            } else {
                isSelectWeekPlan = false
            }
        }
    }
    
    @Published var isSelectWeekPlan: Bool
    
    @Published var isPassTrail: Bool
    
    /// URL для открытия во встроенном WebView
    @Published var selectedURL: URL? = nil

    // MARK: - Private Properties

    private let service: PaywallService
    private let router: PaywallRouter

    
    // MARK: - Init

    init(
        service: PaywallService,
        router: PaywallRouter
    ) {
        self.service = service
        self.router = router
        
        self.isSelectWeekPlan = true
        self.isPassTrail = false
    }

    // MARK: - Public Method
        
    func didTapContinue() {
        router.openHome()
    }
    
    func didTapWeekPlan() {
        isEnabled = true
    }
    
    func didTapMonthPlan() {
        isEnabled = false
    }
    
    func didTapTermsOfUse() {
        if let url = URL(string: "https://www.google.com") {
            selectedURL = url
        }
    }
    
    func didTapPrivacyPolicy() {
        if let url = URL(string: "https://www.apple.com") {
            selectedURL = url
        }
    }
}
