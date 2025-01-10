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

    func openSimilarPhotos(
        groupedPhotos: [[PhotoAsset]]? = nil,
        screenshots: [ScreenshotsAsset]? = nil,
        type: SimilarPhotosType
    ) {
        guard let parentController else { return }
        let viewConreoller = SimilarPhotosAssembly.openSimilarPhotos(
            groupedPhotos: groupedPhotos,
            screenshots: screenshots,
            type: type
        )
        push(viewConreoller, on: parentController)
    }

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
