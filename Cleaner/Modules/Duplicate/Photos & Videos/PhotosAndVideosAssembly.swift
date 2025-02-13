//
//  PhotosAndVideosAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import UIKit

enum PhotosAndVideosAssembly {
    static func openPhotosAndVideos(
        screenType: PhotosAndVideosFromType
    ) -> UIViewController {
        let router = PhotosAndVideosRouter()
        let service = PhotosAndVideosService()
        let viewModel = PhotosAndVideosViewModel(
            service: service,
            router: router,
            screenType: screenType
        )

        let view = PhotosAndVideosView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
