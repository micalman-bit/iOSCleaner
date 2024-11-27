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

    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
