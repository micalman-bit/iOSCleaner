//
//  ContactsRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import UIKit

final class ContactsRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
