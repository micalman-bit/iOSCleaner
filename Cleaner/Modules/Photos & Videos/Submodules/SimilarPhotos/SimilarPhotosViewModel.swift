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

final class SimilarPhotosViewModel: ObservableObject {

    // MARK: - Published Properties
    
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
    
    // MARK: - Private Methods
    
    // Метод для удаления удалённых активов из groupedPhotos
    private func removeDeletedAssets(from deletedAssets: [PHAsset]) {
        for groupIndex in groupedPhotos.indices {
            groupedPhotos[groupIndex].removeAll { photoAsset in
                deletedAssets.contains(where: { $0.localIdentifier == photoAsset.asset.localIdentifier })
            }
        }
    }

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
            
            print("Selected size: \(self.selectedSizeInGB) GB")
        }
    }
    
    private func loadAndAnalyzePhotos() {
        isAnalyzing = true
        groupedPhotos = []
        
        assetManagementService.fetchAndAnalyzePhotos(
            onNewGroupFound: { [weak self] newGroup in
                DispatchQueue.main.async {
                    let photoAssets: [PhotoAsset] = newGroup.enumerated().map { index, asset in
                        PhotoAsset(isSelected: index != 0, asset: asset)
                    }

                    self?.groupedPhotos.append(photoAssets)
                    self?.isAnalyzing = false
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
