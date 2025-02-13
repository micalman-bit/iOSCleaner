//
//  SimilarPhotosAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit

enum SimilarAssetAssembly {
    static func openSimilarAsset(
        photoOrVideo: [[PhotoAsset]]? = nil,
        screenshotsOrRecording: [ScreenshotsAsset]? = nil,
        type: SimilarAssetType,
        backTapAction: @escaping ([DuplicateAssetGroup]?, [ScreenshotsAsset]?) -> Void
    ) -> UIViewController {
        let router = SimilarAssetRouter()
        let service = SimilarAssetService()
        let viewModel = SimilarAssetViewModel(
            service: service,
            router: router,
            photoOrVideo: photoOrVideo,
            screenshotsOrRecording: screenshotsOrRecording,
            type: type,
            backTapAction: backTapAction
        )

        let view = SimilarAssetView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
