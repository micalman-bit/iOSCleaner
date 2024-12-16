//
//  SettingViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 11.12.2024.
//

import Foundation

// MARK: - SettingItemModel

struct SettingItemModel: Identifiable {
    let id: UUID = UUID()
    let title: String
    let action: () -> Void
}

final class SettingViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var listOfItems: [SettingItemModel]

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
            SettingItemModel(
                title: "Send feedback",
                action: {}
            ),
            SettingItemModel(
                title: "Contact support",
                action: {}
            ),
            SettingItemModel(
                title: "Privacy Policy",
                action: {}
            ),
            SettingItemModel(
                title: "Terms of Use",
                action: {}
            ),
        ]
    }
    
    
    // MARK: - Public Methods

    func dismiss() {
        router.dismiss()
    }
}
