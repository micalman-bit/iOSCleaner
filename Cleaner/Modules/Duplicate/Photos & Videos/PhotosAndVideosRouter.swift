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
        type: SimilarAssetType,
        backTapAction: @escaping ([DuplicateAssetGroup]?, [ScreenshotsAsset]?) -> Void
    ) {
        guard let parentController else { return }
        let viewConreoller = SimilarAssetAssembly.openSimilarAsset(
            photoOrVideo: photoOrVideo,
            screenshotsOrRecording: screenshotsOrRecording,
            type: type,
            backTapAction: backTapAction
        )
        push(viewConreoller, on: parentController)
    }

    func openContacts() {
        guard let parentController else { return }
        let viewConreoller = ContactsAssembly.openContacts()
        push(viewConreoller, on: parentController)
    }

    func openCalendar() {
        guard let parentController else { return }
        let viewConreoller = CalendarAssembly.openCalendar()
        push(viewConreoller, on: parentController)
    }

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
