//
//  OnboardingRouter.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import UIKit

final class OnboardingRouter: DefaultRouter {
    // MARK: - Public Properties

    weak var parentController: UIViewController?

    func openPaywall() {
        guard let parentController else { return }
        let viewConreoller = PaywallAssembly.openPaywall()
        push(viewConreoller, on: parentController)
    }
    
    func openHome() {
        guard let parentController else { return }
        let viewConreoller = HomeAssembly.openHome()
        push(viewConreoller, on: parentController)
    }
    
    func dismiss() {
        parentController?.navigationController?.popViewController(animated: true)
    }
}
