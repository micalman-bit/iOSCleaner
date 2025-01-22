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

    func openSimilarAsset(
        photoOrVideo: [[PhotoAsset]]? = nil,
        screenshotsOrRecording: [ScreenshotsAsset]? = nil,
        type: SimilarPhotosType
    ) {
        guard let parentController else { return }
        let viewConreoller = SimilarAssetAssembly.openSimilarAsset(
            photoOrVideo: photoOrVideo,
            screenshotsOrRecording: screenshotsOrRecording,
            type: type
        )
        push(viewConreoller, on: parentController)
    }

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
