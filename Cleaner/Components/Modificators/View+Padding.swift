//
//  View+Padding.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 29.11.2024.
//

import SwiftUI

// swiftformat:disable redundantSelf
extension View {
    func padding(vertical: CGFloat = .zero, horizontal: CGFloat = .zero) -> some View {
        self.padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
    }

    func padding(vertical: CGFloat = .zero, leading: CGFloat = .zero, trailing: CGFloat = .zero) -> some View {
        self.padding(.vertical, vertical)
            .padding(.leading, leading)
            .padding(.trailing, trailing)
    }

    func padding(top: CGFloat = .zero, bottom: CGFloat = .zero, horizontal: CGFloat = .zero) -> some View {
        self.padding(.top, top)
            .padding(.bottom, bottom)
            .padding(.horizontal, horizontal)
    }

    func padding(top: CGFloat = .zero, bottom: CGFloat = .zero, leading: CGFloat = .zero, trailing: CGFloat = .zero) -> some View {
        self.padding(.top, top)
            .padding(.bottom, bottom)
            .padding(.leading, leading)
            .padding(.trailing, trailing)
    }
}
