//
//  Extension + CGFloat.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 29.11.2024.
//

import UIKit

extension CGFloat {
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    func projectedOffset(decelerationRate: UIScrollView.DecelerationRate) -> CGFloat {
        // Magic formula from WWDC
        let multiplier = 1 / (1 - decelerationRate.rawValue) / 1_000
        return self * multiplier
    }
}
