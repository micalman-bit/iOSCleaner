//
//  SettingRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 11.12.2024.
//

import UIKit

final class SettingRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
