//
//  OnboardingAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import UIKit

enum OnboardingAssembly {
    static func openSplash() -> UIViewController {
        let router = OnboardingRouter()
        let service = OnboardingService()
        
        let viewModel = OnboardingViewModel(service: service, router: router)
        let view = OnboardingView(viewModel: viewModel)
        
        let viewController = TAHostingController(rootView: view)
        router.parentController = viewController
        
        return viewController
    }
}
