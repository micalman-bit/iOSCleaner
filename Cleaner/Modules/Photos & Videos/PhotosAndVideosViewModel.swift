//
//  PhotosAndVideosViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import Foundation

// MARK: - SettingItemModel

struct PhotosAndVideosItemModel: Identifiable {
    let id: UUID = UUID()
    let leftTitle: String
    let leftSubtitle: String
    let rightTitle: String
    let action: () -> Void
}

import Foundation
import Photos

import Foundation
import Photos

final class PhotosAndVideosViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var listOfItems: [PhotosAndVideosItemModel]
    @Published var isAnalyzing: Bool = true

    @Published var groupedPhotos: [[PhotoAsset]] = []

    // MARK: - Private Properties

    private let service: PhotosAndVideosService
    private let router: PhotosAndVideosRouter
    private let assetManagementService: AssetManagementService

    // MARK: - Init

    init(
        service: PhotosAndVideosService,
        router: PhotosAndVideosRouter,
        assetManagementService: AssetManagementService = AssetManagementService()
    ) {
        self.service = service
        self.router = router
        self.assetManagementService = assetManagementService
        self.listOfItems = [
//            PhotosAndVideosItemModel(leftTitle: "Screenshots", leftSubtitle: "0", rightTitle: "0 MB", action: {}),
//            PhotosAndVideosItemModel(leftTitle: "Screen recordings", leftSubtitle: "0", rightTitle: "0 MB", action: {}),
//            PhotosAndVideosItemModel(leftTitle: "Similar Photos", leftSubtitle: "0", rightTitle: "0 MB", action: {}),
//            PhotosAndVideosItemModel(leftTitle: "Video Duplicates", leftSubtitle: "0", rightTitle: "0 MB", action: {})
        ]
        
        loadAndAnalyzePhotos()
    }
    
    // MARK: - Public Methods
    
    func dismiss() {
        router.dismiss()
    }

    // MARK: - Private Methods

    private func loadAndAnalyzePhotos() {
        isAnalyzing = true
        groupedPhotos = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.assetManagementService.fetchAndAnalyzePhotos(
                onNewGroupFound: { [weak self] newGroup in
                    DispatchQueue.main.async {
                        let photoAssets: [PhotoAsset] = newGroup.enumerated().map { index, asset in
                            PhotoAsset(isSelected: index != 0, asset: asset)
                        }
                        newGroup.first?.mediaType
                        self?.groupedPhotos.append(photoAssets)
                    }
                },
                completion: { [weak self] in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.listOfItems.append(
                            PhotosAndVideosItemModel(
                                leftTitle: "Similar Photos",
                                leftSubtitle: "\(self.groupedPhotos.count)",
                                rightTitle: "0 MB",
                                action: self.openSimilarPhoto
                            )
                        )

                        self.isAnalyzing = false
                        
                    }
                }
            )
        }
    }

    private func openSimilarPhoto() {
        router.openSimilarPhotos()
    }
}
