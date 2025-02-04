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

//struct PhotoAsset: Identifiable {
//    let id = UUID()
//    var isSelected: Bool
//    let asset: PHAsset
//}
final class PhotoAsset: Identifiable {
    let id = UUID()
    var isSelected: Bool
    let asset: PHAsset

    init(isSelected: Bool, asset: PHAsset) {
        self.isSelected = isSelected
        self.asset = asset
    }
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
    @Published var screenState: ScreenState = .loading

    @Published var selectedPhotos: String = "0"
    @Published var selectedSizeInGB: String = "0"
    
    @Published var groupedPhotos: [[PhotoAsset]] = [] {
        didSet {
            totalPhotos = "\(groupedPhotos.flatMap { $0 }.count)"
            selectedPhotos = "\(groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
            let selectedAssets = groupedPhotos.flatMap { $0 }.filter { $0.isSelected }
            calculateSelectedSize(for: selectedAssets)
            // Если анализ ещё идёт и мы получили какие-либо группы – завершаем анализ
            if isAnalyzing && !groupedPhotos.isEmpty {
                finishAnalysis()
            }
        }
    }
    
    @Published var screenshots: [ScreenshotsAsset] = []
    
    // Процент анализа (0 … 100)
    @Published var analysisProgress: Int = 0
    @Published var isAnalyzing: Bool = false
    @Published var timerText: String = "0%"
    
    // MARK: - Public Properties

    var type: SimilarAssetType
    
    // MARK: - Private Properties

    private let service: SimilarAssetService
    private let router: SimilarAssetRouter
    private var assetService = AssetManagementService.shared
    private var videoManagementService = VideoManagementService.shared

    // Таймер для обновления контента "Photos" (для type == .photos)
    private var photosUpdateTimer: Timer?
    // Таймер для анализа (обновляет analysisProgress и timerText)
    private var analysisTimer: Timer?
    
    private var videosUpdateTimer: Timer?

    // Для обновления групп скриншотов (если нужно)
    // (оставляем без изменений для других типов)
    // …
    
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
            self.loadAndAnalyzePhotos(photoOrVideo)
            
        case .screenshots:
            if let screenshotsOrRecording = screenshotsOrRecording {
                self.screenState = .content
                self.isAnalyzing = false
                self.screenshots = screenshotsOrRecording
                self.groupedPhotos = screenshotsOrRecording.map { $0.groupAsset }
                totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
                selectedPhotos = "\(self.groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
            } else {
                self.isAnalyzing = true
                assetService.fetchScreenshotsGroupedByMonth { [weak self] assets in
                    guard let self else { return }
                    self.screenState = .content
                    self.isAnalyzing = false
                    self.screenshots = assets
                    self.groupedPhotos = assets.map { $0.groupAsset }
                    totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
                    selectedPhotos = "\(self.groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
                }
            }
            
        case .screenRecords:
            let status = videoManagementService.getScreenRecordingsStatus()
            
            if let screenshotsOrRecording = screenshotsOrRecording, status.isScanning {
                self.screenState = .content
                self.isAnalyzing = status.isScanning
                self.screenshots = screenshotsOrRecording
                self.groupedPhotos = screenshotsOrRecording.map { $0.groupAsset }
                totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
                selectedPhotos = "\(self.groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
            } else {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.getScreenRecordsGroups()
                }
            }
            
        }
        
        startAnalysisTimer()
    }

    private func getScreenRecordsGroups() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let status = self.videoManagementService.getScreenRecordingsStatus()
            
            self.screenState = .content
            self.isAnalyzing = status.isScanning
            self.screenshots = status.groups
            self.groupedPhotos = status.groups.map { $0.groupAsset }
            totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
            selectedPhotos = "\(self.groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"

            if !status.isScanning {
                isAnalyzing = false
            } else {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.getScreenRecordsGroups()
                }
            }

        }
        
    }
    // MARK: - Public Methods

    func openSimilarPhotoPicker(groupInex: Int, selectedItemInex: Int) {
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
        photosUpdateTimer?.invalidate()
        analysisTimer?.invalidate()
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
                self?.selectedSizeInGB = totalSize
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
                if let size = size { totalSize += size }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let selectedSizeGB = Double(totalSize) / (1024 * 1024 * 1024)
            self.selectedSizeInGB = "\(String(format: "%.2f", selectedSizeGB))"
        }
    }
    
    private func removeDeletedAssets(from deletedAssets: [PHAsset]) {
        for groupIndex in groupedPhotos.indices {
            groupedPhotos[groupIndex].removeAll { photoAsset in
                deletedAssets.contains { $0.localIdentifier == photoAsset.asset.localIdentifier }
            }
        }
    }
    
    // MARK: - Photo Analysis for Type == .photos

    /// Если type == .photos, каждую 7 секунд запрашиваем статус анализа из AssetManagementService.
    /// Пока isScanning == true – обновляем groupedPhotos и устанавливаем screenState = .loading.
    /// Как только анализ завершён, таймер останавливается, и screenState становится .content (или .allClean, если нет результатов).
    private func loadAndAnalyzePhotos(_ photoOrVideo: [[PhotoAsset]]? = nil) {
        switch type {
        case .photos:
            let status = self.assetService.getScanStatus()
            
            if let photoOrVideo = photoOrVideo {
                self.screenState = .content
                self.groupedPhotos = photoOrVideo
                totalPhotos = "\(groupedPhotos.flatMap { $0 }.count)"
                selectedPhotos = "\(groupedPhotos.flatMap { $0 }.filter { $0.isSelected }.count)"
            }
            
            if status.isScanning {
                photosUpdateTimer?.invalidate()
                DispatchQueue.main.async {
                    self.photosUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        let status = self.assetService.getScanStatus()
                        
                        if !status.groups.isEmpty {
                            self.isAnalyzing = false
                        }
                        
                        if status.isScanning {
                            // Преобразуем группы (из DuplicateAssetGroup) в [[PhotoAsset]]
                            let photoGroups = status.groups.map { group in
                                group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
                            }
                            self.groupedPhotos = photoGroups
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        } else {
                            // Финальное обновление – остановка таймера и переключение состояния
                            self.updatePhotosPanel()
                            timer.invalidate()
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        }
                    })
                }
            } else {
                self.isAnalyzing = false
            }
        case .video:
            let status = videoManagementService.getVideoDuplicatesStatus()
            
            if let photoOrVideo = photoOrVideo {
                self.screenState = .content
                self.isAnalyzing = false
                self.groupedPhotos = photoOrVideo
                self.totalPhotos = "\(groupedPhotos.flatMap { $0 }.count)"
            }
            
            if status.isScanning {
                videosUpdateTimer?.invalidate()
                DispatchQueue.main.async {
                    self.videosUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        // Запрашиваем актуальный статус анализа видео
                        let status = self.videoManagementService.getVideoDuplicatesStatus()
                        
                        // Если группы получены – можно считать, что анализ постепенно завершается
                        if !status.groups.isEmpty {
                            self.isAnalyzing = false
                        }
                        
                        if status.isScanning {
                            // Преобразуем полученные группы (например, типа DuplicateAssetGroup) в [[PhotoAsset]]
                            let videoGroups = status.groups.map { group in
                                group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
                            }
                            self.groupedPhotos = videoGroups
//                            self.groupedVideo = videoGroups
                            
                            // Обновляем общее количество видео (можно использовать тот же totalPhotos, если для UI он универсален)
                            self.totalPhotos = "\(self.groupedPhotos.flatMap { $0 }.count)"
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        } else {
                            // Когда анализ завершён – делаем финальное обновление и останавливаем таймер
                            self.updateVidoPanel()
                            timer.invalidate()
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        }
                    })
                }
            } else {
                self.isAnalyzing = false
            }

        default:
            break
        }
        
        
    }
    
    /// Обновляет плашку "Photos" на основе текущих данных (например, если статус анализа завершён)
    private func updatePhotosPanel() {
        let status = assetService.getScanStatus()
        let photoGroups = status.groups.map { group in
            group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
        }
        self.groupedPhotos = photoGroups
    }

    private func updateVidoPanel() {
        let status = videoManagementService.getVideoDuplicatesStatus()
        let photoGroups = status.groups.map { group in
            group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
        }
        self.groupedPhotos = photoGroups
    }

    // MARK: - Analysis Timer (для независимого обновления progress, если требуется)

    private func startAnalysisTimer() {
        analysisTimer?.invalidate()
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            // Здесь можно обновлять локальный прогресс, если хотите, например,
            // увеличивать analysisProgress на некоторое значение и обновлять timerText.
            // Если же прогресс должен рассчитываться исключительно из AssetManagementService,
            // этот таймер можно не использовать или использовать для анимации.
        }
    }
    
    private func finishAnalysis() {
        analysisTimer?.invalidate()
        analysisProgress = 100
        timerText = "100%"
        isAnalyzing = false
        
        // Если нет найденных групп – считаем, что всё чисто
        if groupedPhotos.isEmpty {
            screenState = .allClean
        } else {
            screenState = .content
        }
    }
    
    /// Объединяет новый список групп с уже существующими данными,
    /// сохраняя значение isSelected для ассетов, которые уже были в groupedPhotos.
    private func mergeGroupedPhotos(newGroups: [[PhotoAsset]]) -> [[PhotoAsset]] {
        return newGroups.map { newGroup in
            newGroup.map { newAsset in
                // Ищем в текущих группах элемент с таким же localIdentifier
                if let oldAsset = groupedPhotos.flatMap({ $0 }).first(where: {
                    $0.asset.localIdentifier == newAsset.asset.localIdentifier
                }) {
                    // Если нашли — используем его состояние isSelected
                    return PhotoAsset(isSelected: oldAsset.isSelected, asset: newAsset.asset)
                } else {
                    // Если не нашли, оставляем текущее значение (либо можно задать дефолтное)
                    return newAsset
                }
            }
        }
    }
}
