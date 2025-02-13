//
//  SplashAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import UIKit

enum SplashAssembly {
    static func openSplash() -> UIViewController {
        let router = SplashRouter()
        let viewModel = SplashViewModel(router: router)

//        UserDefaultsService.isPassOnboarding = false  
        
        let view = SplashView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}

