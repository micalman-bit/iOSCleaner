//
//  TAHostingController.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

/// [Documentation](https://github.com/trend-dev/ta-mobile-ios/blob/master/Documentation/SwiftUI%20Components/Base/Base%20Components.md#ta_hosting_controller)
final class TAHostingController<Content: View>: UIHostingController<Content> {
    // MARK: - Public properties

    var onAppear: ((UIHostingController<Content>) -> Void)?
    var onDisappear: ((UIHostingController<Content>) -> Void)?

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onAppear?(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDisappear?(self)
    }
}
