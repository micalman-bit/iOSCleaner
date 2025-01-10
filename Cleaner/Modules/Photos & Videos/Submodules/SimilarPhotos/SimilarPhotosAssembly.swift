//
//  SimilarPhotosAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit

enum SimilarPhotosAssembly {
    static func openSimilarPhotos(
        groupedPhotos: [[PhotoAsset]]? = nil,
        screenshots: [ScreenshotsAsset]? = nil,
        type: SimilarPhotosType
    ) -> UIViewController {
        let router = SimilarPhotosRouter()
        let service = SimilarPhotosService()
        
        let viewModel = SimilarPhotosViewModel(
            service: service,
            router: router,
            groupedPhotos: groupedPhotos,
            screenshots: screenshots,
            type: type
        )

        let view = SimilarPhotosView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
