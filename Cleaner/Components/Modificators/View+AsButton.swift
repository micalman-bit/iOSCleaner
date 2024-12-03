//
//  View+AsButton.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 01.12.2024.
//

import SwiftUI

// MARK: - ButtonAnimationStyle

enum ButtonAnimationStyle {
    /// При нажатии `View` становится полупрозрачной. Рекомендуется для текстовых кнопок и элементов, вложенных внутрь других `View`.
    case opacity
    /// При нажатии `View` немного уменьшается (продавливается). Рекомендуется для крупных карточек и кнопок с фоном.
    case scale(ScaleButtonAnimationWeight)
}

// MARK: - ScaleButtonAnimationWeight

enum ScaleButtonAnimationWeight {
    /// Небольшое уменьшение для крупных `View`
    case light
    /// Сильное уменьшение для мелких `View`
    case heavy

    var scale: CGFloat {
        switch self {
        case .light:
            return 0.98
        case .heavy:
            return 0.96
        }
    }
}

// MARK: - View + asButton

extension View {
    /// Используется по аналогии с `onTapGesture { ... }`.
    /// Но в отличие от `onTapGesture { ... }` добавляет анимацию нажатия на __любую__ используемую `View`.
    @ViewBuilder func asButton(
        style: ButtonAnimationStyle,
        action: @escaping () -> Void
    ) -> some View {
        switch style {
        case .opacity:
            Button(action: action, label: { self }).buttonStyle(OpacityButtonAnimationStyle())
        case let .scale(weight):
            Button(action: action, label: { self }).buttonStyle(ScaleButtonAnimationStyle(weight: weight))
        }
    }
}

// MARK: - OpacityButtonAnimationStyle

private struct OpacityButtonAnimationStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: configuration.isPressed ? 0 : 0.2), value: configuration.isPressed)
    }
}

// MARK: - ScaleButtonAnimationStyle

private struct ScaleButtonAnimationStyle: ButtonStyle {
    private let weight: ScaleButtonAnimationWeight

    init(weight: ScaleButtonAnimationWeight) {
        self.weight = weight
    }

    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? weight.scale : 1)
            .animation(.easeOut(duration: configuration.isPressed ? 0.15 : 0.3), value: configuration.isPressed)
    }
}

