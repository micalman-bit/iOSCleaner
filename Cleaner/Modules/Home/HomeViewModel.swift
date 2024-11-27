//
//  HomeViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

final class HomeViewModel: ObservableObject {
    
    // MARK: - Private Properties

    private let service: HomeService
    private let router: HomeRouter

    // MARK: - Init

    init(
        service: HomeService,
        router: HomeRouter
    ) {
        self.service = service
        self.router = router
    }
    
    
}
