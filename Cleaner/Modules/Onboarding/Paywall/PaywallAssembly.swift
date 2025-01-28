//
//  PaywallAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import UIKit

enum PaywallAssembly {
    static func openPaywall() -> UIViewController {
        let service = PaywallService()
        let router = PaywallRouter()
        
        let viewModel = PaywallViewModel(service: service, router: router)
        let view = PaywallView(viewModel: viewModel)
        
        let viewController = TAHostingController(rootView: view)
        router.parentController = viewController
        return viewController
    }
}
