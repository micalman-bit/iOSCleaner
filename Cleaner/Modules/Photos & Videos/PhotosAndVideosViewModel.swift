//
//  PhotosAndVideosViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import Foundation
import Photos

struct PhotosAndVideosItemModel: Identifiable {
    let id: UUID = UUID()
    let leftTitle: String
    var leftSubtitle: String
    let rightTitle: String
    let action: () -> Void
}

final class PhotosAndVideosViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var listOfItems: [PhotosAndVideosItemModel]
    @Published var isAnalyzing: Bool = true

    // MARK: - Private Properties

    private let service: PhotosAndVideosService
    private let router: PhotosAndVideosRouter
    private let assetManagementService: AssetManagementService

    private var groupedPhotos: [[PhotoAsset]] = []
    private var groupedOnlyPhotos: [[PhotoAsset]] = []
    private var groupedOnlyScreenshots: [ScreenshotsAsset] = []

    // MARK: - Init

    init(
        service: PhotosAndVideosService,
        router: PhotosAndVideosRouter,
        assetManagementService: AssetManagementService = AssetManagementService()
    ) {
        self.service = service
        self.router = router
        self.assetManagementService = assetManagementService
        self.listOfItems = []
        
        loadAndAnalyzePhotos()
    }
    
    // MARK: - Public Methods
    
    func dismiss() {
        router.dismiss()
    }

    // MARK: - Private Methods

    // Search photo duplicates
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
                        self?.groupedPhotos.append(photoAssets)
                    }
                },
                completion: { [weak self] in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        
                        let photoAssets = self.groupedPhotos.flatMap { $0 }
                        PhotoVideoManager.shared.calculateStorageUsageForAssets(photoAssets) { photoSize in
                            self.listOfItems.append(
                                PhotosAndVideosItemModel(
                                    leftTitle: "Photos",
                                    leftSubtitle: "\(photoAssets.count)",
                                    rightTitle: String(format: "%.2f GB", photoSize),
                                    action: self.openPhotos
                                )
                            )

                            self.analyzeScreenshots()
                        }
                    }
                }
            )
        }
    }
    
    // Search screenshots
    private func analyzeScreenshots() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.assetManagementService.fetchScreenshotsGroupedByMonth { [weak self] groupedScreenshots in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.groupedOnlyScreenshots = groupedScreenshots
                    
                    let screenshotAssets = self.groupedOnlyScreenshots.flatMap { $0.groupAsset }
                    
                    PhotoVideoManager.shared.calculateStorageUsageForAssets(screenshotAssets) { screenshotSize in
                        self.listOfItems.append(
                            PhotosAndVideosItemModel(
                                leftTitle: "Screenshots",
                                leftSubtitle: "\(screenshotAssets.count)",
                                rightTitle: String(format: "%.2f GB", screenshotSize),
                                action: self.openScreenshots
                            )
                        )
                        
                        self.isAnalyzing = false
                    }
                }
            }
        }
    }

    func calculateStorageUsageForAssets(_ assets: [PHAsset], completion: @escaping (Double) -> Void) {
        var totalSize: Double = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            assets.forEach { asset in
                if let resource = PHAssetResource.assetResources(for: asset).first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += Double(fileSize)
                }
            }
            
            DispatchQueue.main.async {
                completion(totalSize / 1_073_741_824) // Конвертируем в GB
            }
        }
    }

    private func openScreenshots() {
        router.openSimilarPhotos(
            screenshots: groupedOnlyScreenshots,
            type: .screenshots
        )
    }

    private func openPhotos() {
        router.openSimilarPhotos(
            groupedPhotos: groupedPhotos,
            type: .photos
        )
    }
}
