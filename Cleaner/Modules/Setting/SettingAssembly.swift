//
//  SettingAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 11.12.2024.
//

import UIKit

enum SettingAssembly {
    static func openSetting() -> UIViewController {
        let router = SettingRouter()
        let service = SettingService()
        let viewModel = SettingViewModel(
            service: service,
            router: router
        )

        let view = SettingView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
