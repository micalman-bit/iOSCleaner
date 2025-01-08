//
//  PhotosAndVideosRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import UIKit

final class PhotosAndVideosRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?

    func openSimilarPhotos() {
        guard let parentController else { return }
        let viewConreoller = SimilarPhotosAssembly.openSimilarPhotos()
        push(viewConreoller, on: parentController)
    }

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
