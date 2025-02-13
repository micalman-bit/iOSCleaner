//
//  CalendarAssembly.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import UIKit

enum CalendarAssembly {
    static func openCalendar(
    ) -> UIViewController {
        let router = CalendarRouter()
        let service = CalendarService()
        
        let viewModel = CalendarViewModel(
            service: service,
            router: router
        )

        let view = CalendarView(viewModel: viewModel)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}
