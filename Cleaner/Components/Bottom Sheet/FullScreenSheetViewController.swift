//
//  FullScreenSheetViewController.swift
//  Trendagent
//
//  Created by Maksim Golov on 26.09.2023.
//

import UIKit

/// SheetViewController, открывающийся всегда во весь экран (независимо от размера контента)
class FullScreenSheetViewController: SheetViewController {
    override var contentPreferredHeight: CGFloat {
        .infinity
    }

    override func backgroundView(for presentationController: UIPresentationController) -> UIView? {
        view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.bounces = false
    }
}
