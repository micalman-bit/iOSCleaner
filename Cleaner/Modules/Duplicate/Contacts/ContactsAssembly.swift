//
//  ContactsAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import UIKit

enum ContactsAssembly {
    static func openContacts(
    ) -> UIViewController {
        let router = ContactsRouter()
        let service = ContactsService()
        
        let viewModel = ContactsViewModel(
            service: service,
            router: router
        )

        let view = ContactsView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
