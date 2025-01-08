//
//  SimilarPhotosAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit

enum SimilarPhotosAssembly {
    static func openSimilarPhotos() -> UIViewController {
        let router = SimilarPhotosRouter()
        let service = SimilarPhotosService()
        
        let viewModel = SimilarPhotosViewModel(
            service: service,
            router: router
        )

        let view = SimilarPhotosView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
