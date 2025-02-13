//
//  SettingViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 11.12.2024.
//

import SwiftUI

// MARK: - SettingItemModel

struct SettingItemModel: Identifiable {
    let id: UUID = UUID()
    let title: String
    let action: () -> Void
}

final class SettingViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var listOfItems: [SettingItemModel] = []
    @Published var selectedURL: URL? = nil

    // MARK: - Private Properties

    private let service: SettingService
    private let router: SettingRouter
    
    // MARK: - Init

    init(
        service: SettingService,
        router: SettingRouter
    ) {
        self.service = service
        self.router = router

        listOfItems = [
            SettingItemModel(
                title: "Restore Purchase",
                action: {}
            ),
//            SettingItemModel(
//                title: "Send feedback",
//                action: {}
//            ),
//            SettingItemModel(
//                title: "Contact support",
//                action: {}
//            ),
            SettingItemModel(
                title: "Privacy Policy",
                action: self.didTapPrivacyPolicy
            ),
            SettingItemModel(
                title: "Terms of Use",
                action: self.didTapTermsOfUse
            ),
        ]
    }
    
    
    // MARK: - Public Methods

    func dismiss() {
        router.dismiss()
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
