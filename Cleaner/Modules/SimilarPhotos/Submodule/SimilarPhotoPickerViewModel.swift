//
//  SimilarPhotoPickerViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 21.12.2024.
//

import Foundation
import Photos

final class SimilarPhotoPickerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedImage: PHAsset

    // MARK: - Private Properties

    private let router: SimilarPhotoPickerRouter
    
    
    // MARK: - Public Properties

    var assets: [PHAsset]
    
    // MARK: - Init

    init(
        router: SimilarPhotoPickerRouter,
        assets: [PHAsset],
        selectedImage: PHAsset
    ) {
        self.router = router
        self.assets = assets
        self.selectedImage = selectedImage
    }
 
    // MARK: - Public Func
    
    func dismiss() {
        router.dismiss()
    }

}
