//
//  PulseButtonStyle.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 17.02.2025.
//

import SwiftUI

struct PulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Немного уменьшаем кнопку при нажатии
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            // Анимация входа/выхода
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
