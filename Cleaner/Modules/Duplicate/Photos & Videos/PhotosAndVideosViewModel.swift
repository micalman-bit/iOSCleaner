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
    @Published var timerText: String = "0%"
    
    // MARK: - Private Properties

    private let service: PhotosAndVideosService
    private let router: PhotosAndVideosRouter
    
    private let videoManagementService: VideoManagementService
    private var assetService = AssetManagementService.shared
    
    private var groupedPhotos: [[PhotoAsset]] = []
    private var groupedScreenshots: [ScreenshotsAsset] = []
    
    private var groupedVideo: [[PhotoAsset]] = []
    private var groupedScreenRecords: [ScreenshotsAsset] = []

    // MARK: - Init

    init(
        service: PhotosAndVideosService,
        router: PhotosAndVideosRouter
    ) {
        self.service = service
        self.router = router
        
        self.videoManagementService = VideoManagementService()
        self.listOfItems = []
        
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
            guard let self = self else { return }

            while true {
                let status = self.assetService.getScanStatus()
                let scanning = status.isScanning
                let progress = status.progress
                let groupsCount = status.groups.count

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("Updating progress: \(progress)")
                    self.timerText = "\(Int(progress))%"
                }
                
                print("scanning: \(scanning), progress: \(progress), duplicates found: \(groupsCount)")

                if groupsCount > 1 {
                    DispatchQueue.main.async {
                        self.isAnalyzing = false
                    }
                    break
                }

                Thread.sleep(forTimeInterval: 0.5)
            }

            // 3. Когда цикл завершён (сканирование закончилось)
            let finalStatus = self.assetService.getScanStatus()
            let finalGroups = finalStatus.groups
            
            print("Final scanning: \(finalStatus.isScanning), progress: \(finalStatus.progress), duplicates found: \(finalGroups.count)")
            
            let arrayOfPhotoAssets = finalGroups.map { $0.assets }
            
            // 4. Переходим на главный поток, чтобы обновить UI
            DispatchQueue.main.async {
                // Если хотите ещё и тут отключить, если вдруг ещё не отключили
                self.isAnalyzing = false
                
                self.groupedPhotos = arrayOfPhotoAssets
                let allPhotoAssets = arrayOfPhotoAssets.flatMap { $0 }

                PhotoVideoManager.shared.calculateStorageUsageForAssets(allPhotoAssets) { [weak self] photoSize in
                    guard let self = self else { return }
                    
                    self.listOfItems.append(
                        PhotosAndVideosItemModel(
                            leftTitle: "Photos",
                            leftSubtitle: "\(allPhotoAssets.count)",
                            rightTitle: String(format: "%.2f GB", photoSize),
                            action: { [weak self] in
                                guard let self = self else { return }
                                self.openSimilarAsset(
                                    photoOrVideo: self.groupedPhotos,
                                    type: .photos
                                )
                            }
                        )
                    )

                    self.analyzeScreenshots()
                }
            }
        }
    }

    // Search screenshots
    private func analyzeScreenshots() {
        self.fetchAndAnalyzeVideos()
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            self?.assetManagementService.fetchScreenshotsGroupedByMonth { [weak self] groupedScreenshots in
//                DispatchQueue.main.async {
//                    guard let self else { return }
//                    self.groupedScreenshots = groupedScreenshots
//                    
//                    let screenshotAssets = self.groupedScreenshots.flatMap { $0.groupAsset }
//                    
//                    PhotoVideoManager.shared.calculateStorageUsageForAssets(screenshotAssets) { screenshotSize in
//                        self.listOfItems.append(
//                            PhotosAndVideosItemModel(
//                                leftTitle: "Screenshots",
//                                leftSubtitle: "\(screenshotAssets.count)",
//                                rightTitle: String(format: "%.2f GB", screenshotSize),
//                                action: { [weak self] in
//                                    guard let self else { return }
//                                    self.openSimilarAsset(
//                                        screenshotsOrRecording: groupedScreenshots,
//                                        type: .screenshots
//                                    )
//                                }
//                            )
//                        )
//                        
//                        self.fetchAndAnalyzeVideos()
//                    }
//                }
//            }
//        }
    }

    // Search Video
    private func fetchAndAnalyzeVideos() {
        videoManagementService.fetchAndAnalyzeVideos(
            onNewGroupFound: { [weak self] newVideo in
                guard let self else { return }
                print("FIND VIDEO")
                let photoAssets: [PhotoAsset] = newVideo.enumerated().map { index, asset in
                    PhotoAsset(isSelected: index != 0, asset: asset)
                }
                self.groupedVideo.append(photoAssets)

            },
            completion: { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    print("completion VIDEO")
                    
                    let videoAssets = self.groupedVideo.flatMap { $0 }
                    
                    self.listOfItems.append(
                        PhotosAndVideosItemModel(
                            leftTitle: "Video Duplicates",
                            leftSubtitle: "\(videoAssets.count)",
                            rightTitle: "",//String(format: "%.2f GB", screenshotSize),
                            action: { [weak self] in
                                guard let self else { return }
                                self.openSimilarAsset(
                                    photoOrVideo: groupedVideo,
                                    type: .video
                                )
                            }
                        )
                    )
                    
                    self.fetchAndAnalyzeSceenRecords()
                }
                
            }
        )
    }
    
    // Search Screen record
    private func fetchAndAnalyzeSceenRecords() {
        videoManagementService.fetchScreenRecordingsGroupedByMonth(
            completion: { [weak self] sceenRecords in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.groupedScreenRecords = sceenRecords
                    
                    let screenRecordsAssets = self.groupedScreenRecords.flatMap { $0.groupAsset }
                    
                    PhotoVideoManager.shared.calculateStorageUsageForAssets(screenRecordsAssets) { screenRecordsSize in
                        self.listOfItems.append(
                            PhotosAndVideosItemModel(
                                leftTitle: "Screen recordings",
                                leftSubtitle: "\(screenRecordsAssets.count)",
                                rightTitle: String(format: "%.2f GB", screenRecordsSize),
                                action: { [weak self] in
                                    guard let self else { return }
                                    self.openSimilarAsset(
                                        screenshotsOrRecording: groupedScreenRecords,
                                        type: .screenRecords
                                    )
                                }
                            )
                        )
                        
                        self.isAnalyzing = false
                    }
                }

            }
        )
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

    private func openSimilarAsset(
        photoOrVideo: [[PhotoAsset]]? = nil,
        screenshotsOrRecording: [ScreenshotsAsset]? = nil,
        type: SimilarAssetType
    ) {
        router.openSimilarAsset(
            photoOrVideo: photoOrVideo,
            screenshotsOrRecording: screenshotsOrRecording,
            type: type
        )
    }
}
