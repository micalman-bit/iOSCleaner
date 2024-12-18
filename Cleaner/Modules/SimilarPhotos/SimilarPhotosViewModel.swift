//
//  SimilarPhotosViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import Foundation
import Photos
import Vision
import Combine

final class SimilarPhotosViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var groupedPhotos: [[PHAsset]] = []
    @Published var isAnalyzing: Bool = true

    // MARK: - Private Properties

    private let service: SimilarPhotosService
    private let router: SimilarPhotosRouter
    private let assetManagementService: AssetManagementService

    // MARK: - Init

    init(
        service: SimilarPhotosService,
        router: SimilarPhotosRouter,
        assetManagementService: AssetManagementService = AssetManagementService()
    ) {
        self.service = service
        self.router = router
        self.assetManagementService = assetManagementService
        
        self.fetchAndAnalyzePhotos()
    }

    // MARK: - Public Methods

    func dismiss() {
        router.dismiss()
    }
    
    // MARK: - Private Methods
    
    private func fetchAndAnalyzePhotos() {
        isAnalyzing = true

        assetManagementService.fetchAndAnalyzePhotos { [weak self] groupedPhotos in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.groupedPhotos = groupedPhotos
                self.isAnalyzing = false

                if groupedPhotos.isEmpty {
                    print("No similar photos found.")
                } else {
                    print("Found \(groupedPhotos.count) groups of similar photos.")
                }
            }
        }
    }
    
 }
