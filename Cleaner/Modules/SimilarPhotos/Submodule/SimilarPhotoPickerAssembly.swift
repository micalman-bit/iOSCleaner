//
//  SimilarPhotoPickerAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 21.12.2024.
//

import UIKit
import Photos

enum SimilarPhotoPickerAssembly {
    static func openSimilarPhotoPicker(
        _ assets: [PHAsset],
        selectedImage: PHAsset
    ) -> UIViewController {
        
        let router = SimilarPhotoPickerRouter()
        
        let viewModel = SimilarPhotoPickerViewModel(
            router: router,
            assets: assets,
            selectedImage: selectedImage
        )
        
        let view = SimilarPhotoPickerView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
