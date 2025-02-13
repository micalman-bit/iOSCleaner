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

    func openSimilarPhotos(screenType: PhotosAndVideosFromType) {
        guard let parentController else { return }
        let viewConreoller = PhotosAndVideosAssembly.openPhotosAndVideos(
            screenType: screenType
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

    func openSettings() {
        guard let parentController else { return }
        let viewConreoller = SettingAssembly.openSetting()
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
