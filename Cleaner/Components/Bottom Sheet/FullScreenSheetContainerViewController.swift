//
//  FullScreenSheetContainerViewController.swift
//  Trendagent
//
//  Created by Максим Голов on 07.08.2024.
//

import Foundation
import UIKit

/// Sheet-wrapper for custom controllers
final class FullScreenSheetContainerViewController: FullScreenSheetViewController {
    // MARK: - Initializers

    init(viewController: UIViewController) {
        super.init()

//        addChild(viewController, to: contentView) {
//            $0.edges.equalToSuperview()
//        }
    }

    required init?(coder aDecoder: NSCoder) { nil }
}
