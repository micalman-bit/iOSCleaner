//
//  SheetBackgroundLayer.swift
//  Trendagent
//
//  Created by Maksim Golov on 09.03.2024.
//

import Foundation
import UIKit

// MARK: - SheetBackgroundLayer

final class SheetBackgroundLayer: CAGradientLayer {
    // MARK: - Types

    enum Style {
        /// Обычный бэкграунд
        case solid(UIColor)
        /// Градиент
        case gradient([UIColor])
    }

    // MARK: - Initialisers

    init(style: Style) {
        super.init()

        switch style {
        case let .solid(color):
            self.backgroundColor = color.cgColor
        case let .gradient(colors):
            self.colors = colors.map(\.cgColor)
            self.startPoint = .init(x: 0, y: 0)
            self.endPoint = .init(x: 1, y: 0)
        }
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
