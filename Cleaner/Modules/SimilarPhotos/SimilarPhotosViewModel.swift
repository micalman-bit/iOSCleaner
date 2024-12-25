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
        
        self.loadAndAnalyzePhotos()
    }

    // MARK: - Public Methods

    func openSimilarPhotoPicker(
        groupInex: Int,
        selectedItemInex: Int
    ) {
        router.openSimilarPhotoPicker(
            groupedPhotos[groupInex],
            selectedImage: groupedPhotos[groupInex][selectedItemInex]
        )
    }
    
    func dismiss() {
        router.dismiss()
    }
    
    // MARK: - Private Methods
    
    func loadAndAnalyzePhotos() {
        isAnalyzing = true
        groupedPhotos = []
        
        assetManagementService.fetchAndAnalyzePhotos(
            onNewGroupFound: { [weak self] newGroup in
                DispatchQueue.main.async {
                    self?.groupedPhotos.append(newGroup)
                }
            },
            completion: { [weak self] in
                DispatchQueue.main.async {
                    self?.isAnalyzing = false
                }
            }
        )
    }

 }
