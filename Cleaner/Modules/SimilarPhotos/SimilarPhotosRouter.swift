//
//  SimilarPhotosRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit
import Photos

final class SimilarPhotosRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?
    
    func openSimilarPhotoPicker(
        _ assets: [PHAsset],
        selectedImage: PHAsset
    ) {
        guard let parentController else { return }
        let viewConreoller = SimilarPhotoPickerAssembly.openSimilarPhotoPicker(
            assets,
            selectedImage: selectedImage
        )
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
