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

struct PhotoAsset: Identifiable {
    let id = UUID()
    var isSelected: Bool
    let asset: PHAsset
}

struct ScreenshotsAsset {
    let description: String
    let groupAsset: [PhotoAsset]
}

enum SimilarAssetType {
    case photos
    case screenshots
    case video
    case screenRecords
}

final class SimilarAssetViewModel: ObservableObject {

    // MARK: - Published Properties
    
    @Published var title: String
    
    @Published var totalPhotos: String = "0"

    @Published var selectedPhotos: String = "0"
    @Published var selectedSizeInGB: String = "0"
    
    @Published var groupedPhotos: [[PhotoAsset]] = [] {
        didSet {
            totalPhotos = "\(groupedPhotos.flatMap { $0 }.count)"
            
            selectedPhotos = "\(groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"

            let selectedPhotoAssets = groupedPhotos.flatMap { $0 }
                .filter { $0.isSelected }

            print("Selected photo count: \(selectedPhotoAssets.count)")
            
            calculateSelectedSize(for: selectedPhotoAssets)

            print("Selected size: \(selectedSizeInGB) GB")
            print("Total photos: \(totalPhotos)")
            print("Selected photos: \(selectedPhotos)")
        }
    }
    
    @Published var screenshots: [ScreenshotsAsset] = []
    
    @Published var analysisProgress: Int = 0 // Прогресс в процентах
    @Published var isAnalyzing: Bool

    private var assetService = AssetManagementService.shared

    // MARK: - Public Properties

    var type: SimilarAssetType
    
    // MARK: - Private Properties

    private let service: SimilarAssetService
    private let router: SimilarAssetRouter
    
//    private let assetManagementService: AssetManagementService

    // MARK: - Init

    init(
        service: SimilarAssetService,
        router: SimilarAssetRouter,
        photoOrVideo: [[PhotoAsset]]? = nil,
        screenshotsOrRecording: [ScreenshotsAsset]? = nil,
        type: SimilarAssetType,
        assetManagementService: AssetManagementService = AssetManagementService()
    ) {
        self.service = service
        self.router = router
        self.type = type
//        self.assetManagementService = assetManagementService
        
        // TODO: - Вынести по отдельным методам
        switch type {
        case .photos:
            title = "Similar Photos"
        case .video:
            title = "Video Duplicates"
        case .screenshots:
            title = "Screenshots"
        case .screenRecords:
            title = "Screen Recordings"
        }
        
        switch type {
        case .photos, .video:
            if let photoOrVideo {
                self.isAnalyzing = false
                self.groupedPhotos = photoOrVideo
                
                totalPhotos = "\(groupedPhotos.flatMap { $0 }.count)"
                
                selectedPhotos = "\(groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
            } else {
                self.isAnalyzing = true
                self.loadAndAnalyzePhotos()
            }
        case .screenshots, .screenRecords:
            if let screenshotsOrRecording {
                self.isAnalyzing = false
                self.screenshots = screenshotsOrRecording
                self.groupedPhotos = screenshots.map { $0.groupAsset }
                
                totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
                selectedPhotos = "\(self.groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
                
            } else {
                self.isAnalyzing = true
            }
        }
    }

    // MARK: - Public Methods

    func openSimilarPhotoPicker(
        groupInex: Int,
        selectedItemInex: Int
    ) {
        router.openSimilarPhotoPicker(
            groupedPhotos[groupInex],
            selectedImage: groupedPhotos[groupInex][selectedItemInex],
            sucessAction: { [weak self] group in
                self?.groupedPhotos[groupInex] = group
            }
        )
    }
    
    func dismiss() {
        router.dismiss()
    }
    
    func deletePhoto() {
        let assetsToDelete = groupedPhotos.flatMap { $0 }
            .filter { $0.isSelected }
            .map { $0.asset }

        guard !assetsToDelete.isEmpty else {
            print("No photos selected for deletion.")
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Selected photos deleted successfully.")
                    self.removeDeletedAssets(from: assetsToDelete)
                } else if let error = error {
                    print("Error deleting photos: \(error.localizedDescription)")
                }
            }
        })
    }
    
    func recalculateSelectedSize() {
        let selectedAssets = groupedPhotos.flatMap { $0 }.filter { $0.isSelected }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(selectedAssets) { [weak self] totalSize in
            DispatchQueue.main.async {
                self?.selectedSizeInGB = String(format: "%.2f", totalSize)
            }
        }
    }

    // MARK: - Private Methods
    
    private func calculateSelectedSize(for assets: [PhotoAsset]) {
        var totalSize: Int64 = 0
        let dispatchGroup = DispatchGroup()
        
        for photoAsset in assets {
            dispatchGroup.enter()
            photoAsset.asset.getFileSize { size in
                if let size = size {
                    totalSize += size
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            let selectedSizeGB = Double(totalSize) / (1024 * 1024 * 1024)
            self.selectedSizeInGB = "\(String(format: "%.2f", selectedSizeGB))"
        }
    }

    // Метод для удаления удалённых активов из groupedPhotos
    private func removeDeletedAssets(from deletedAssets: [PHAsset]) {
        for groupIndex in groupedPhotos.indices {
            groupedPhotos[groupIndex].removeAll { photoAsset in
                deletedAssets.contains(where: { $0.localIdentifier == photoAsset.asset.localIdentifier })
            }
        }
    }

    private func loadAndAnalyzePhotos() {
        isAnalyzing = true
        groupedPhotos = []
        
        let status = assetService.getScanStatus()
        let scanning = status.isScanning         // Bool
        let progress = status.progress           // Double (0..1)
        let groups = status.groups               // [DuplicateAssetGroup]
        print("scanning: \(scanning), progress: \(progress), duplicates found: \(groups.count)")
        
    }

}

// ВЫНЕСТИ В ОТДЕЛЬНЫЙ ФАЙЛ
import Photos

extension PHAsset {
    func getFileSize(completion: @escaping (Int64?) -> Void) {
        guard let resource = PHAssetResource.assetResources(for: self).first else {
            completion(nil)
            return
        }
        
        if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
            completion(fileSize)
        } else {
            // Если размер не определён напрямую, попробуем альтернативный метод
            fetchFileSizeUsingManager(resource: resource, completion: completion)
        }
    }
    
    private func fetchFileSizeUsingManager(resource: PHAssetResource, completion: @escaping (Int64?) -> Void) {
        var totalSize: Int64 = 0
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true // Разрешаем загрузку из iCloud

        PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { data in
            totalSize += Int64(data.count)
        }) { error in
            if let error = error {
                print("Error fetching size: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(totalSize)
            }
        }
    }
}
