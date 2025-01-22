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

    @Published var selectedImage: PhotoAsset

    // MARK: - Private Properties

    private let router: SimilarPhotoPickerRouter
    
    private let sucessAction: ([PhotoAsset]) -> Void
    
    // MARK: - Public Properties

    var assets: [PhotoAsset]
    
    // MARK: - Init

    init(
        router: SimilarPhotoPickerRouter,
        assets: [PhotoAsset],
        selectedImage: PhotoAsset,
        sucessAction: @escaping ([PhotoAsset]) -> Void
    ) {
        self.router = router
        self.assets = assets
        self.selectedImage = selectedImage
        self.sucessAction = sucessAction
    }
 
    // MARK: - Public Func
    
    func dismiss() {
        sucessAction(assets)
        router.dismiss()
    }

}
