//
//  View + TextStyle.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

// MARK: - FontTemplate

final class FontTemplate {
    private var id: UUID
    var font: Font
    var weight: Font.Weight
    var foregroundColor: Color
    var lineSpacing: CGFloat

    init(
        font: Font,
        weight: Font.Weight,
        foregroundColor: Color,
        lineSpacing: CGFloat = 1.2
    ) {
        self.id = UUID()
        self.font = font
        self.weight = weight
        self.foregroundColor = foregroundColor
        self.lineSpacing = lineSpacing
    }
}

// MARK: - FontTemplateModifier

struct FontTemplateModifier: ViewModifier {
    let template: FontTemplate

    init(template: FontTemplate) {
        self.template = template
    }

    func body(content: Content) -> some View {
        content
            .font(template.font.weight(template.weight))
            .lineSpacing(template.lineSpacing)
            .foregroundColor(template.foregroundColor)
            .padding(.vertical, 1.5)
    }
}

// MARK: - View + TextStyle

extension View {
    func taTextStyle(_ style: FontStyle, textColor: Color = .Typography.textDark) -> some View {
        let fontModifier = FontTemplateModifier(template: style.fontTemplate(color: textColor))
        return modifier(fontModifier)
    }
}
