//
//  SimilarPhotosRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit
import Photos

final class SimilarAssetRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?
    
    func openSimilarPhotoPicker(
        _ assets: [PhotoAsset],
        selectedImage: PhotoAsset,
        sucessAction: @escaping ([PhotoAsset]) -> Void
    ) {
        guard let parentController else { return }
        let viewConreoller = SimilarPhotoPickerAssembly.openSimilarPhotoPicker(
            assets,
            selectedImage: selectedImage,
            sucessAction: sucessAction
        )
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
