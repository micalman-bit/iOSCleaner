//
//  CheckBoxView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 22.01.2025.
//

import SwiftUI

struct CheckBoxView: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                .background(Circle().fill(isSelected ? Color.blue.opacity(0.3) : Color.clear))
                .frame(width: 24, height: 24)
        }
    }
}
