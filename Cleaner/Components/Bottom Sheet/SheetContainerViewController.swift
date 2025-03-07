//
//  SheetContainerViewController.swift
//
//
//  Created by Максим Голов on 04.04.2022.
//

import UIKit

// MARK: - SheetContainerViewController

/// Sheet-wrapper for custom controllers
class SheetContainerViewController: SheetViewController {
    // MARK: - Initializers

    init(viewController: UIViewController, ignoreSafeArea: Bool = false) {
        super.init(ignoreSafeArea: ignoreSafeArea)

//        addChild(viewController, to: contentView) {
//            $0.edges.equalToSuperview()
//        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}

// MARK: - SheetContainerNavigationViewController

/// Sheet-wrapper for custom controllers
final class SheetContainerNavigationViewController: SheetViewController {
    // MARK: - Initializers

    init(viewController: UINavigationController) {
        super.init()

//        addChild(viewController, to: contentView) {
//            $0.edges.equalToSuperview()
//            $0.height.equalTo(.screenHeight * 0.8)
//        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}
