//
//  View+MaskedCorners.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 29.11.2024.
//

import SwiftUI

// MARK: - RoundedCorner

private struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: .init(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View + MaskedCorners

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
