//
//  SimilarPhotosRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.12.2024.
//

import UIKit

final class SimilarPhotosRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
