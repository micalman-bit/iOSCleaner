//
//  HomeRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import UIKit

final class HomeRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?

    func openSimilarPhotos() {
        guard let parentController else { return }
        let viewConreoller = PhotosAndVideosAssembly.openPhotosAndVideos()
//        let viewConreoller = SimilarPhotosAssembly.openSimilarPhotos()

        push(viewConreoller, on: parentController)
    }
    
    func openSettings() {
        guard let parentController else { return }
        let viewConreoller = SettingAssembly.openSetting()
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
