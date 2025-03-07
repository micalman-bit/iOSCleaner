//
//  SelfSizingTableView.swift
//
//
//  Created by Maksim Golov on 25.02.2022.
//

import UIKit

final class SelfSizingTableView: UITableView {
    // MARK: - Private Properties

    private var heightConstraint: NSLayoutConstraint?

    // MARK: - UICollectionView

    override var contentSize: CGSize {
        // Высота не должна быть нулевой, иначе UITableView даже не пытается отрисовываться и загружать ячейки
        didSet {
            heightConstraint?.constant = max(1, contentSize.height + contentInset.top + contentInset.bottom)
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Private Methods

    private func setupUI() {
        heightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: .greatestFiniteMagnitude)
        heightConstraint?.isActive = true
        isScrollEnabled = false

        if #available(iOS 15.0, *) {
            sectionHeaderTopPadding = 0
        }
    }
}
