//
//  PhotosAndVideosViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import Photos
import Combine
import SwiftUI

struct PhotosAndVideosItemModel: Identifiable {
    let id: UUID = UUID()
    let leftTitle: String
    var leftSubtitle: String
    var rightTitle: String
    let action: () -> Void
}

final class PhotosAndVideosViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var listOfItems: [PhotosAndVideosItemModel]
    @Published var isAnalyzing: Bool = false
    @Published var timerText: String = "0%"
    @Published var analysisProgress: Double = 0.0   // Значение от 0.0 до 1.0

    // MARK: - Private Properties

    private let service: PhotosAndVideosService
    private let router: PhotosAndVideosRouter
    
    private let videoManagementService = VideoManagementService.shared
    private var assetService = AssetManagementService.shared
    
    private var groupedPhotos: [[PhotoAsset]] = []
    private var groupedScreenshots: [ScreenshotsAsset] = []
    
    private var groupedVideo: [[PhotoAsset]] = []
    private var groupedScreenRecords: [ScreenshotsAsset] = []

    // Таймер для обновления панели скриншотов
    private var screenshotsUpdateTimer: Timer?
    private var lastScreenshotsSummary: [(String, Int)] = []

    // Таймер для обновления текстового прогресса (timerText) независимо от loadAndAnalyzePhotos
    private var progressTimer: Timer?
    

    // Таймер для обновления панели фотографий
    private var photosUpdateTimer: Timer?

    // Таймер для обновления панели фотографий
    private var videoUpdateTimer: Timer?
    private var sceenRecordsUpdateTimer: Timer?

    // MARK: - Init

    init(
        service: PhotosAndVideosService,
        router: PhotosAndVideosRouter
    ) {
        self.service = service
        self.router = router
        
        self.listOfItems = [
            PhotosAndVideosItemModel(
                leftTitle: "Photos",
                leftSubtitle: "0",
                rightTitle: "0 GB",
                action: { }
            ),
            
            PhotosAndVideosItemModel(
                leftTitle: "Screenshots",
                leftSubtitle: "0",
                rightTitle: "0 GB",
                action: { }
            ),
            
            PhotosAndVideosItemModel(
                leftTitle: "Video Duplicates",
                leftSubtitle: "0",
                rightTitle: "0 GB",
                action: { }
            ),
            
            PhotosAndVideosItemModel(
                leftTitle: "Screen recordings",
                leftSubtitle: "0",
                rightTitle: "0 GB",
                action: { }
            )
        ]
        
        loadAndAnalyzePhotos()
        startProgressTimer()
    }
    
    // MARK: - Public Methods
    
    func dismiss() {
        router.dismiss()
        photosUpdateTimer?.invalidate()
        screenshotsUpdateTimer?.invalidate()
    }
    
    
    
    func startAnalysis() {
        isAnalyzing = true
        analysisProgress = 0.0
        timerText = "0%"
        startProgressTimer()
        loadAndAnalyzePhotos()
    }

    // MARK: - Photo Analysis
    
    private func loadAndAnalyzePhotos() {
        groupedPhotos = []
        
        updatePhotosPanel()
        analyzeScreenshots()
        
        // Запускаем таймер обновления "Photos" каждые 7 секунд
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.photosUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let status = self.assetService.getScanStatus()
                
                self.updatePhotosPanel()
                
                if !status.isScanning {
                    self.updatePhotosPanel()
                    timer.invalidate()
                }
            })
        }
    }
    
    /// Обновляет плашку "Photos" в списке (либо добавляет новый элемент, если его ещё нет)
    private func updatePhotosPanel() {
        let status = assetService.getScanStatus()
        let groups = status.groups
        let arrayOfPhotoAssets = groups.map { $0.assets }
        
        self.groupedPhotos = arrayOfPhotoAssets
        let allPhotoAssets = arrayOfPhotoAssets.flatMap { $0 }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(allPhotoAssets) { [weak self] formattedSize in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let countString = "\(allPhotoAssets.count)"
                let newItem = PhotosAndVideosItemModel(
                    leftTitle: "Photos",
                    leftSubtitle: countString,
                    rightTitle: formattedSize,
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.openSimilarAsset(photoOrVideo: self.groupedPhotos, type: .photos)
                    }
                )
                self.updateListItem(with: newItem)
//                if let index = self.listOfItems.firstIndex(where: { $0.leftTitle == "Photos" }) {
//                    // Обновляем существующий элемент, не заменяя его
//                    self.listOfItems[index].leftSubtitle = countString
//                    self.listOfItems[index].rightTitle = formattedSize
//                } else {
//
//                    self.listOfItems.append(newItem)
//                }
            }
        }
    }

    // MARK: - Screenshots Analysis

    private func analyzeScreenshots() {
        updateScreenshotsPanel { newGroups in
            self.lastScreenshotsSummary = newGroups.map { ($0.description, $0.groupAsset.count) }
        }
        
        fetchAndAnalyzeVideos()// ?
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.screenshotsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                self.updateScreenshotsPanel { newGroups in
                    let newSummary = newGroups.map { ($0.description, $0.groupAsset.count) }
                    if newSummary.elementsEqual(self.lastScreenshotsSummary, by: { (lhs, rhs) in
                        return lhs.0 == rhs.0 && lhs.1 == rhs.1
                    }) {
                        timer.invalidate()
//                        self.fetchAndAnalyzeVideos()
                    } else {
                        self.lastScreenshotsSummary = newSummary
                    }
                }
            })
        }
    }
    
    /// Обновляет плашку "Screenshots" в списке с расчетом объёма занимаемого места.
    private func updateScreenshotsPanel(completion: (([ScreenshotsAsset]) -> Void)? = nil) {
        assetService.fetchScreenshotsGroupedByMonth { [weak self] screenshots in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.groupedScreenshots = screenshots
                let screenshotAssets = screenshots.flatMap { $0.groupAsset }
                PhotoVideoManager.shared.calculateStorageUsageForAssets(screenshotAssets) { formattedSize in
                    DispatchQueue.main.async { [weak self] in
                        let newItem = PhotosAndVideosItemModel(
                            leftTitle: "Screenshots",
                            leftSubtitle: "\(screenshotAssets.count)",
                            rightTitle: formattedSize,
                            action: { [weak self] in
                                guard let self = self else { return }
                                self.openSimilarAsset(screenshotsOrRecording: screenshots, type: .screenshots)
                            }
                        )
                        
                        self?.updateListItem(with: newItem)
                        completion?(screenshots)
                    }
                }
            }
        }
    }
    
    // MARK: - Videos Analysis
    
    /// Запускает анализ видео с промежуточными обновлениями.
    /// При каждом обнаружении новой группы дубликатов обновляется плашка "Video Duplicates".
    /// После завершения анализа видео запускается анализ экранных записей.
    private func fetchAndAnalyzeVideos() {
        updateVideosPanel()
        fetchAndAnalyzeSceenRecords()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.videoUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let status = videoManagementService.getVideoDuplicatesStatus()
                
                self.updateVideosPanel()
                
                if !status.isScanning {
                    self.updateVideosPanel()
                    timer.invalidate()
                }
            })
        }
    }
    
    /// Обновляет (или добавляет) плашку "Video Duplicates" на основании найденных групп дубликатов видео.
    /// Теперь производится расчёт занимаемого места с помощью форматирования – результат отображается в rightTitle.
    private func updateVideosPanel(final: Bool = false) {
        let status = videoManagementService.getVideoDuplicatesStatus()
        let groups = status.groups
        let arrayOfVideoAssets = groups.map { $0.assets }

        self.groupedVideo = arrayOfVideoAssets
        let videoAssets = self.groupedVideo.flatMap { $0 }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(videoAssets) { formattedSize in
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Video Duplicates",
                leftSubtitle: "\(videoAssets.count)",
                rightTitle: formattedSize,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.openSimilarAsset(photoOrVideo: self.groupedVideo, type: .video)
                }
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        }
    }
    
    // MARK: - Screen Recordings Analysis
    
    /// Запускает анализ экранных записей (screen recordings).
    private func fetchAndAnalyzeSceenRecords() {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sceenRecordsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let status = videoManagementService.getScreenRecordingsStatus()
                
                self.updateSceenRecordsPanel()
                
                if !status.isScanning {
                    self.updateSceenRecordsPanel()
                    timer.invalidate()
                }
            })
        }
    }
    
    private func updateSceenRecordsPanel() {
        let status = videoManagementService.getScreenRecordingsStatus()
        let groups = status.groups
        let arrayOfScreenRecordingsAssets = groups.map { $0 }
        
        self.groupedScreenRecords = arrayOfScreenRecordingsAssets
        let groupedScreenAssets = self.groupedScreenRecords.flatMap { $0.groupAsset }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(groupedScreenAssets) { formattedSize in
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Screen recordings",
                leftSubtitle: "\(groupedScreenAssets.count)",
                rightTitle: formattedSize,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.openSimilarAsset(photoOrVideo: self.groupedVideo, type: .screenRecords)
                }
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        }
    }

    // MARK: - Utility Methods
    
    func calculateStorageUsageForAssets(_ assets: [PHAsset], completion: @escaping (String) -> Void) {
        var totalSize: Double = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            assets.forEach { asset in
                if let resource = PHAssetResource.assetResources(for: asset).first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += Double(fileSize)
                }
            }
            
            DispatchQueue.main.async {
                // Здесь используется новая логика форматирования размера
                completion(self.formatByteCount(Int64(totalSize)))
            }
        }
    }
    
    private func formatByteCount(_ bytes: Int64) -> String {
        if bytes >= 1_073_741_824 { // 1 GB
            let value = Double(bytes) / 1_073_741_824.0
            return String(format: "%.2f GB", value)
        } else if bytes >= 1_048_576 { // 1 MB
            let value = Double(bytes) / 1_048_576.0
            return String(format: "%.2f MB", value)
        } else if bytes >= 1024 { // 1 KB
            let value = Double(bytes) / 1024.0
            return String(format: "%.2f KB", value)
        } else {
            return "\(bytes) B"
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
    
    // MARK: - Tiemer
    
    private func startProgressTimer() {
        // Сброс значений
        self.analysisProgress = 0.0
        self.timerText = "0%"
        self.isAnalyzing = true

        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            // Увеличиваем прогресс на 1/7 (≈0.142857) каждый тик
            self.analysisProgress += 1.0 / 7.0

            if self.analysisProgress >= 1.0 {
                self.analysisProgress = 1.0
                self.timerText = "100%"
                timer.invalidate()
                // После 7 секунд (как только достигнут 100%) переключаем флаг анализа
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                }
            } else {
                self.timerText = "\(Int(self.analysisProgress * 100))%"
            }
        }
    }

    private func updateListItem(with newItem: PhotosAndVideosItemModel) {
        if let index = listOfItems.firstIndex(where: { $0.leftTitle == newItem.leftTitle }) {
            listOfItems[index] = newItem
        } else {
            listOfItems.append(newItem)
        }
    }
}
