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
    // Dependencies
    private let assetManagementService: AssetManagementService

    // Published properties for UI updates
    @Published var groupedPhotos: [[PHAsset]] = []
    @Published var isAnalyzing: Bool = true

    // Initialization
    init(assetManagementService: AssetManagementService = AssetManagementService()) {
        self.assetManagementService = assetManagementService
        fetchAndAnalyzePhotos()
    }

    // Fetch and analyze photos
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


