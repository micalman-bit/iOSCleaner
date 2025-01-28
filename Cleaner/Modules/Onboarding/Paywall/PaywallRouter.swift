//
//  PaywallRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import UIKit

final class PaywallRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?

    func openHome() {
        guard let parentController else { return }
        let viewConreoller = HomeAssembly.openHome()
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
