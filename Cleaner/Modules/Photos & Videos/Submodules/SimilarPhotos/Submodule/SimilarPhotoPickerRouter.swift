//
//  SimilarPhotoPickerRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 21.12.2024.
//

import UIKit

final class SimilarPhotoPickerRouter: DefaultRouter {
    // MARK: - Public Properties
    
    weak var parentController: UIViewController?
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}

