//
//  HomeAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

enum HomeAssembly {
    static func openHome() -> UIViewController {
        let router = HomeRouter()
        let service = HomeService()
        let viewModel = HomeViewModel(
            service: service,
            router: router
        )

        let view = HomeView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
