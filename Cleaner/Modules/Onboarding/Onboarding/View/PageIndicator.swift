//
//  PageIndicator.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import SwiftUI

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray) // Цвет активного индикатора
                        .frame(width: 20, height: 6) // Удлинённый активный индикатор
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5)) // Цвет неактивных индикаторов
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}
