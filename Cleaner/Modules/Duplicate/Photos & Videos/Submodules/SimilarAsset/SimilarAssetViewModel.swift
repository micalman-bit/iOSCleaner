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
import SwiftUI

// Дополнительные enum'ы/сервисы могут быть у вас определены где-то выше
enum SelectItemsType {
    case all
    case group
}

enum SimilarAssetType {
    case photos
    case screenshots
    case video
    case screenRecords
}

//// Ваш объект экрана — например, состояния экрана
//enum ScreenState {
//    case content
//    case loading
//    case allClean
//}

// PhotoAsset — без изменений
final class PhotoAsset: Identifiable {
    let id = UUID()
    var isSelected: Bool
    let asset: PHAsset
    
    init(isSelected: Bool, asset: PHAsset) {
        self.isSelected = isSelected
        self.asset = asset
    }
}

struct ScreenshotsAsset: Identifiable {
    let id = UUID()
    let title: String
    var isSelectedAll: Bool = false
    var groupAsset: [PhotoAsset]
}

// MARK: - SimilarAssetViewModel

final class SimilarAssetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var title: String
    @Published var totalPhotos: String = "0"
    @Published var screenState: ScreenState = .content
    
    @Published var selectedPhotos: String = "0"
    @Published var selectedSizeInGB: String = "0"
    
    // Теперь это массив DuplicateAssetGroup, в котором есть поле isSelectedAll
    @Published var groupedPhotos: [DuplicateAssetGroup] = [] {
        didSet {
            // Пересчитываем общее количество
            totalPhotos = "\(groupedPhotos.flatMap { $0.assets }.count)"
            // Сколько выбрано
            let allSelected = groupedPhotos.flatMap { $0.assets }.filter { $0.isSelected }
//            selectedPhotos = "\(allSelected.count)"
            // Считаем размер
            calculateSelectedSize(for: allSelected)
            
            // Если анализ ещё идёт и мы получили какие-либо группы – завершаем анализ
            if isAnalyzing && !groupedPhotos.isEmpty {
                finishAnalysis()
            }
        }
    }
    
    @Published var screenshots: [ScreenshotsAsset] = []
    
    @Published var isEnabledButton: Bool = false
    
    @Published var analysisProgress: Int = 0
    @Published var isAnalyzing: Bool = false
    @Published var timerText: String = "0%"
    
    @Published var isSeselectAllButtonText: String = "Select All"
    @Published var isSeselectAllButtonColor: Color = .blue
    
    @Published var toggleGroupText: String = "Select All"
    @Published var toggleGroupTextColor: Color = .blue
    
    // MARK: - Public Properties
    
    var type: SimilarAssetType
    
    // MARK: - Private Properties
    
    private let service: SimilarAssetService
    private let router: SimilarAssetRouter
    
    private var assetService = AssetManagementService.shared
    private var videoManagementService = VideoManagementService.shared
    
    private var photosUpdateTimer: Timer?
    private var analysisTimer: Timer?
    private var videosUpdateTimer: Timer?
    
    private let backTapAction: ([DuplicateAssetGroup]?, [ScreenshotsAsset]?, Bool) -> Void
    
    private var isDataLoadedAndShow: Bool = false
    
    // MARK: - Инициализация
    
    init(
        service: SimilarAssetService,
        router: SimilarAssetRouter,
        photoOrVideo: [[PhotoAsset]]? = nil,
        screenshotsOrRecording: [ScreenshotsAsset]? = nil,
        type: SimilarAssetType,
        backTapAction: @escaping ([DuplicateAssetGroup]?, [ScreenshotsAsset]?, Bool) -> Void,
        assetManagementService: AssetManagementService = AssetManagementService()
    ) {
        self.service = service
        self.router = router
        self.type = type
        self.backTapAction = backTapAction
        
        switch type {
        case .photos:
            title = "Similar Photos"
        case .video:
            title = "Video Duplicates"
        case .screenshots:
            title = "Screenshots"
        case .screenRecords:
            title = "Recordings"
        }
        setDefaultDataToBottomButton()
        
        switch type {
        case .photos, .video:
            loadAndAnalyzePhotos(photoOrVideo)
            checkStatusForSeselectAll()
            recalculateSelectedSize()
            isDataLoadedAndShow = true
        case .screenshots:
            if let screenshotsOrRecording = screenshotsOrRecording {
                self.screenState = .content
                self.isAnalyzing = false
                
                self.screenshots = screenshotsOrRecording.map {
                    let screenshotsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                    let allSelected = screenshotsAsset.allSatisfy { $0.isSelected }
                    return ScreenshotsAsset(title: $0.title, isSelectedAll: allSelected, groupAsset: screenshotsAsset)
                }

                totalPhotos = "\(self.screenshots.flatMap { $0.groupAsset }.count)"
//                selectedPhotos = "\(self.screenshots.flatMap { $0.groupAsset }.filter { $0.isSelected }.count)"
                
                checkStatusForSeselectAll()
                recalculateSelectedSize()
                isDataLoadedAndShow = true
            } else {
                self.isAnalyzing = true
                assetService.fetchScreenshotsGroupedByMonth { [weak self] assets in
                    guard let self = self else { return }
                    self.screenState = .content
                    self.isAnalyzing = false
                    
                    self.screenshots = assets.map {
                        let screenshotsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                        let allSelected = screenshotsAsset.allSatisfy { $0.isSelected }
                        return ScreenshotsAsset(title: $0.title, isSelectedAll: allSelected, groupAsset: screenshotsAsset)
                    }
                    self.totalPhotos = "\(self.screenshots.flatMap { $0.groupAsset }.count)"
//                    self.selectedPhotos = "\(self.screenshots.flatMap { $0.groupAsset }.filter { $0.isSelected }.count)"
                    
                    checkStatusForSeselectAll()
                    recalculateSelectedSize()
                    isDataLoadedAndShow = true
                }
            }
        case .screenRecords:
            let status = videoManagementService.getScreenRecordingsStatus()
            if let screenshotsOrRecording = screenshotsOrRecording, status.isScanning {
                self.screenState = .content
                self.isAnalyzing = status.isScanning

                self.screenshots = screenshotsOrRecording.map {
                    let screenRecordsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                    let allSelected = screenRecordsAsset.allSatisfy { $0.isSelected }
                    return ScreenshotsAsset(title: $0.title, isSelectedAll: allSelected, groupAsset: screenRecordsAsset)
                }
                self.groupedPhotos = screenshotsOrRecording.map {
                    let screenRecordsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                    let allSelected = screenRecordsAsset.allSatisfy { $0.isSelected }

                    return DuplicateAssetGroup(isSelectedAll: allSelected, assets: screenRecordsAsset)
                }
                
                totalPhotos = "\(self.groupedPhotos.flatMap { $0.assets }.count)"
//                selectedPhotos = "\(self.groupedPhotos.flatMap { $0.assets }.filter { $0.isSelected }.count)"
                
                checkStatusForSeselectAll()
                recalculateSelectedSize()
                isDataLoadedAndShow = true
            } else {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.getScreenRecordsGroups()
                }
            }
        }
        
        startAnalysisTimer()
//        recalculateSelectedSize()
//        checkStatusForSeselectAll()
    }
    
    // MARK: - Public Methods

    func setSelectToItemsByType(
        itemsType: SelectItemsType,
        groupAssets: DuplicateAssetGroup? = nil,
        screenshot: ScreenshotsAsset? = nil
    ) {
        switch type {
        case .photos, .video:
            switch itemsType {
            case .group:
                guard let groupAssets else { return }
                guard let groupIndex = groupedPhotos.firstIndex(where: {
                    $0.assets.map(\.id) == groupAssets.assets.map(\.id)
                }) else {
                    return
                }
                
                var group = groupedPhotos[groupIndex]
                
                // Если сейчас все выбраны – снимаем, иначе выбираем
                let needSelectAll = !group.assets.dropFirst().allSatisfy { $0.isSelected }
                
                var updatedAssets = group.assets.map {
                    PhotoAsset(isSelected: needSelectAll, asset: $0.asset)
                }
                
                
                group.assets = updatedAssets
                group.isSelectedAll = needSelectAll
                
                if needSelectAll, let isSelected = groupedPhotos[groupIndex].assets.first?.isSelected, !isSelected  {
                    group.assets.first?.isSelected = false
                }
                
                groupedPhotos[groupIndex] = group
                

                checkStatusForSeselectAll()
                
            case .all:
                // Проверяем, выбраны ли все ассеты во всех группах
                let allSelected = groupedPhotos
                    .flatMap { $0.assets.dropFirst() }
                    .allSatisfy { $0.isSelected }
                
                let needSelect = !allSelected
                // Обновляем каждый group
                groupedPhotos = groupedPhotos.map { oldGroup in
                    var group = oldGroup
                    let newAssets = group.assets.map {
                        PhotoAsset(isSelected: needSelect, asset: $0.asset)
                    }
                    group.assets = newAssets
                    group.isSelectedAll = needSelect
                    
                    if needSelect, let isSelected = oldGroup.assets.first?.isSelected, !isSelected  {
                        group.assets.first?.isSelected = false
                    }

                    return group
                }
                
                checkStatusForSeselectAll()
            }
            
        case .screenshots, .screenRecords:
            switch itemsType {
            case .group:
                guard let screenshot else { return }
                guard let groupIndex = screenshots.firstIndex(where: {
                    $0.groupAsset.map(\.id) == screenshot.groupAsset.map(\.id)
                }) else {
                    return
                }
                
                var group = screenshots[groupIndex]
                
                let needSelectAll = !group.groupAsset.allSatisfy { $0.isSelected }
                
                let updatedAssets = group.groupAsset.map {
                    PhotoAsset(isSelected: needSelectAll, asset: $0.asset)
                }
                
                group.groupAsset = updatedAssets
                group.isSelectedAll = needSelectAll
                screenshots[groupIndex] = group
                
                checkStatusForSeselectAll()
                
            case .all:
                // Проверяем, выбраны ли все ассеты во всех группах
                let allSelected = screenshots
                    .flatMap { $0.groupAsset }
                    .allSatisfy { $0.isSelected }
                
                let needSelect = !allSelected
                // Обновляем каждый group
                screenshots = screenshots.map { oldGroup in
                    var group = oldGroup
                    let newAssets = group.groupAsset.map {
                        PhotoAsset(isSelected: needSelect, asset: $0.asset)
                    }
                    group.groupAsset = newAssets
                    group.isSelectedAll = needSelect
                    return group
                }
                
                checkStatusForSeselectAll()
            }

        }
        
        recalculateSelectedSize()
    }
    
    private func checkStatusForSeselectAll() {
        let allSelected: Bool
        switch type {
        case .photos, .video:
            allSelected = groupedPhotos.flatMap { $0.assets.dropFirst() }.allSatisfy { $0.isSelected }
        case .screenRecords, .screenshots:
            allSelected = screenshots.flatMap { $0.groupAsset }.allSatisfy { $0.isSelected }
        }

        if allSelected {
            isSeselectAllButtonText = "Deselect All"
            isSeselectAllButtonColor = .gray
            
            toggleGroupText = "Deselect All"
            toggleGroupTextColor = .gray
        } else {
            isSeselectAllButtonText = "Select All"
            isSeselectAllButtonColor = .blue
            
            toggleGroupText = "Select All"
            toggleGroupTextColor = .blue
        }
    }
    
    func getGridList(
        assets: DuplicateAssetGroup,
        screenshot: ScreenshotsAsset
    ) -> [PhotoAsset] {
        switch type {
        case .photos, .video:
            return assets.assets
        case .screenRecords, .screenshots:
            return screenshot.groupAsset
        }
    }

    /// Открывает подробный просмотр группы (например, карусель или что-то ещё)
    func openSimilarPhotoPicker(groupInex: Int, selectedItemInex: Int) {
        let currentGroup: [PhotoAsset]
        switch type {
        case .photos, .video:
            currentGroup = groupedPhotos[groupInex].assets
        case .screenshots, .screenRecords:
            currentGroup = screenshots[groupInex].groupAsset
        }
            
        
        let selectedItem = currentGroup[selectedItemInex]
        
        router.openSimilarPhotoPicker(
            currentGroup,
            selectedImage: selectedItem,
            sucessAction: { [weak self] newAssets in
                guard let self = self else { return }
                // Обновляем группу
                switch type {
                case .photos, .video:
                    var group = self.groupedPhotos[groupInex]
                    group.assets = newAssets
                    group.isSelectedAll = newAssets.allSatisfy { $0.isSelected }
                    self.groupedPhotos[groupInex] = group
                    
                case .screenshots, .screenRecords:
                    var group = self.screenshots[groupInex]
                    group.groupAsset = newAssets
                    group.isSelectedAll = newAssets.allSatisfy { $0.isSelected }
                    self.screenshots[groupInex] = group

                }
                self.recalculateSelectedSize()
            }
        )
    }
    
    func dismiss() {
        backTapAction(groupedPhotos, screenshots, isDataLoadedAndShow)
        router.dismiss()
        
        photosUpdateTimer?.invalidate()
        analysisTimer?.invalidate()
        videosUpdateTimer?.invalidate()
    }
    
    /// Удаление выбранных ассетов
    func deletePhoto() {
        let assetsToDelete: [PHAsset]
        guard isEnabledButton else { return }
        switch type {
        case .photos, .video:
            assetsToDelete = groupedPhotos
                .flatMap { $0.assets }
                .filter { $0.isSelected }
                .map { $0.asset }
        case .screenshots, .screenRecords:
            assetsToDelete = screenshots
                .flatMap { $0.groupAsset }
                .filter { $0.isSelected }
                .map { $0.asset }
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
        
    /// Пересчитываем суммарный размер выбранных ассетов (и обновляем UI-кнопки)
    func recalculateSelectedSize() {
        let selectedAssets: [PhotoAsset]
        switch type {
        case .photos, .video:
            selectedAssets = groupedPhotos.flatMap { $0.assets }.filter { $0.isSelected }
        case .screenRecords, .screenshots:
            selectedAssets = screenshots.flatMap { $0.groupAsset }.filter { $0.isSelected }
        }
        PhotoVideoManager.shared.calculateStorageUsageForAssets(selectedAssets) { [weak self] totalSize in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.selectedSizeInGB = totalSize
                self.isEnabledButton = !selectedAssets.isEmpty
                
                // Для кнопки выводим разный текст в зависимости от типа
                switch self.type {
                case .photos:
                    if selectedAssets.isEmpty {
                        self.selectedPhotos = "DELETE PHOTOS"
                        self.selectedSizeInGB = ""
                    } else {
                        self.selectedPhotos = "DELETE \(selectedAssets.count) PHOTOS"
                    }
                case .screenshots:
                    if selectedAssets.isEmpty {
                        self.selectedPhotos = "DELETE SCREENSHOTS"
                        self.selectedSizeInGB = ""
                    } else {
                        self.selectedPhotos = "DELETE \(selectedAssets.count) SCREENSHOTS"
                    }
                case .video:
                    if selectedAssets.isEmpty {
                        self.selectedPhotos = "DELETE VIDEO"
                        self.selectedSizeInGB = ""
                    } else {
                        self.selectedPhotos = "DELETE \(selectedAssets.count) VIDEO"
                    }
                case .screenRecords:
                    if selectedAssets.isEmpty {
                        self.selectedPhotos = "DELETE RECORDINGS"
                        self.selectedSizeInGB = ""
                    } else {
                        self.selectedPhotos = "DELETE \(selectedAssets.count) VIDEO"
                    }
                }
            }
        }
    }
    
    /// Тап по чекбоксу (или другой элемент) в списке, переключающий выбор одного ассета
    func toggleSelection(for asset: PhotoAsset) {
        switch type {
        case .photos, .video:
            if let groupIndex = groupedPhotos.firstIndex(where: { group in
                group.assets.contains(where: { $0.id == asset.id })
            }) {
                var group = groupedPhotos[groupIndex]
                var newAssets = group.assets
                
                if let assetIndex = newAssets.firstIndex(where: { $0.id == asset.id }) {
                    newAssets[assetIndex].isSelected.toggle()
                }
                // Пересчитываем isSelectedAll
                let allSelected = newAssets.allSatisfy { $0.isSelected }
                group.isSelectedAll = allSelected
                
                group.assets = newAssets
                groupedPhotos[groupIndex] = group
                
                checkStatusForSeselectAll()
                recalculateSelectedSize()
            }
        case .screenshots, .screenRecords:
            if let groupIndex = screenshots.firstIndex(where: { group in
                group.groupAsset.contains(where: { $0.id == asset.id })
            }) {
                var group = screenshots[groupIndex]
                var newAssets = group.groupAsset
                
                if let assetIndex = newAssets.firstIndex(where: { $0.id == asset.id }) {
                    newAssets[assetIndex].isSelected.toggle()
                }
                // Пересчитываем isSelectedAll
                let allSelected = newAssets.allSatisfy { $0.isSelected }
                group.isSelectedAll = allSelected
                
                group.groupAsset = newAssets
                screenshots[groupIndex] = group
                
                checkStatusForSeselectAll()
                recalculateSelectedSize()
            }
        }
    }
    
    // MARK: - Вспомогательные методы (размер, время и т.д.)
    
    func getVideoDurationString(_ asset: PHAsset) -> String {
        guard asset.mediaType == .video else { return "00:00" }
        
        let totalSeconds = Int(asset.duration.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getFormattedFileSize(_ asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let resourceType: PHAssetResourceType = (asset.mediaType == .video) ? .video : .photo
        
        guard let resource = resources.first(where: { $0.type == resourceType }) else {
            return "0 B"
        }
        
        if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
            return formatByteCount(fileSize)
        }
        return "0 B"
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
    
    // MARK: - Приватные методы
    
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
            self.selectedSizeInGB = String(format: "%.2f", selectedSizeGB)
        }
    }
    
    private func removeDeletedAssets(from deletedAssets: [PHAsset]) {
        let deletedIDs = deletedAssets.map { $0.localIdentifier }
        print("Удаляются ассеты с идентификаторами: \(deletedIDs)")
        
        // Фильтруем каждую группу, удаляя ассеты из массива
        var newGroups: [DuplicateAssetGroup] = []
        switch type {
        case .photos, .video:
            for oldGroup in groupedPhotos {
                // Убираем удалённые ассеты
                let filtered = oldGroup.assets.filter { photoAsset in
                    !deletedAssets.contains { $0.localIdentifier == photoAsset.asset.localIdentifier }
                }
                // Если эта группа всё ещё имеет смысл
                if (type == .photos || type == .video) {
                    // Например, оставляем группу, только если >= 2 элементов
                    if filtered.count >= 2 {
                        // Допустим, заново задаём isSelected у первой и последующих (пример)
                        // Или оставляем как есть. Здесь на ваше усмотрение.
                        // Ниже просто оставим, как есть, кроме пересчёта isSelectedAll
                        let allSelected = filtered.allSatisfy { $0.isSelected }
                        let newGroup = DuplicateAssetGroup(
                            isSelectedAll: allSelected,
                            assets: filtered
                        )
                        newGroups.append(newGroup)
                    }
                } else {
                    // Для скриншотов/записей экрана достаточно не выкидывать пустые
                    if !filtered.isEmpty {
                        let allSelected = filtered.allSatisfy { $0.isSelected }
                        let newGroup = DuplicateAssetGroup(
                            isSelectedAll: allSelected,
                            assets: filtered
                        )
                        newGroups.append(newGroup)
                    }
                }
            }
            
            groupedPhotos = newGroups
            
            if groupedPhotos.isEmpty {
                screenState = .allClean
            }

        case .screenshots, .screenRecords:
            // Если это скриншоты или экранные записи – синхронизируем screenshots
            if type == .screenshots || type == .screenRecords {
                var newScreens: [ScreenshotsAsset] = []
                
                for oldGroup in screenshots {
                    let filtered = oldGroup.groupAsset.filter { photoAsset in
                        !deletedAssets.contains { $0.localIdentifier == photoAsset.asset.localIdentifier
                        }
                    }

                    if filtered.count >= 1 {
                        let allSelected = filtered.allSatisfy { $0.isSelected }
                        
                        let newGroup = ScreenshotsAsset(
                            title: oldGroup.title,
                            isSelectedAll: allSelected,
                            groupAsset: filtered
                        )
                        newScreens.append(newGroup)
                    } else {
                        if !filtered.isEmpty {

                            let allSelected = filtered.allSatisfy { $0.isSelected }
                            newScreens.append(
                                ScreenshotsAsset(
                                    title: oldGroup.title,
                                    isSelectedAll: allSelected,
                                    groupAsset: filtered
                                )
                            )
                        }
                    }
                }
                
                screenshots = newScreens
                
                if screenshots.isEmpty {
                    screenState = .allClean
                }
            }
        }
                
        recalculateSelectedSize()
    }
    
    // MARK: - Photo/Video Analysis
    
    private func loadAndAnalyzePhotos(_ photoOrVideo: [[PhotoAsset]]? = nil) {
        switch type {
        case .photos:
            let status = assetService.getScanStatus()
            
            // Если уже есть готовые данные
            if let photoOrVideo = photoOrVideo {
                self.screenState = .content
                // Преобразуем в [DuplicateAssetGroup]
                self.groupedPhotos = photoOrVideo.map {
                    let allSelected = $0.allSatisfy { $0.isSelected }
                    
                    let photoAssetArray = $0.enumerated().map { index, asset in
                        return PhotoAsset(isSelected: index == 0 ? false : true, asset: asset.asset)
                    }
                    
                    return DuplicateAssetGroup(isSelectedAll: allSelected, assets: photoAssetArray)
                }
                totalPhotos = "\(groupedPhotos.flatMap { $0.assets }.count)"
//                selectedPhotos = "\(groupedPhotos.flatMap { $0.assets }.filter { $0.isSelected }.count)"
            }
            
            // Если сканирование ещё идёт
            if status.isScanning {
                photosUpdateTimer?.invalidate()
                DispatchQueue.main.async {
                    self.photosUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        let status = self.assetService.getScanStatus()
                        
                        if !status.groups.isEmpty {
                            self.isAnalyzing = false
                        }
                        
                        if status.isScanning {
                            // Преобразуем новые группы
                            let newPhotoGroups: [DuplicateAssetGroup] = status.groups.map { group in
                                let photoAssets = group.assets.map {
                                    PhotoAsset(isSelected: false, asset: $0.asset)
                                }
                                let allSelected = photoAssets.allSatisfy { $0.isSelected }
                                return DuplicateAssetGroup(isSelectedAll: allSelected, assets: photoAssets)
                            }
                            // Мержим, чтобы не потерять isSelected
                            self.groupedPhotos = self.mergeGroupedPhotos(newGroups: newPhotoGroups)
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                            
                        } else {
                            self.updatePhotosPanel()
                            timer.invalidate()
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        }
                    }
                }
            } else {
                // Анализ завершён
                if groupedPhotos.isEmpty {
                    screenState = .allClean
                } else {
                    screenState = .content
                }
                self.isAnalyzing = false
            }
            
        case .video:
            let status = videoManagementService.getVideoDuplicatesStatus()
            
            if let photoOrVideo = photoOrVideo {
                self.screenState = .content
                self.isAnalyzing = false
                self.groupedPhotos = photoOrVideo.map {
                    let allSelected = $0.allSatisfy { $0.isSelected }
                    
                    let videoAssetArray = $0.enumerated().map { index, asset in
                        return PhotoAsset(isSelected: index == 0 ? false : true, asset: asset.asset)
                    }

                    return DuplicateAssetGroup(isSelectedAll: allSelected, assets: videoAssetArray)
                }
                self.totalPhotos = "\(groupedPhotos.flatMap { $0.assets }.count)"
            }
            
            if status.isScanning {
                videosUpdateTimer?.invalidate()
                DispatchQueue.main.async {
                    self.videosUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        let status = self.videoManagementService.getVideoDuplicatesStatus()
                        
                        if !status.groups.isEmpty {
                            self.isAnalyzing = false
                        }
                        
                        if status.isScanning {
                            let videoGroups: [DuplicateAssetGroup] = status.groups.map { group in
                                let assets = group.assets.map {
                                    PhotoAsset(isSelected: false, asset: $0.asset)
                                }
                                let allSelected = assets.allSatisfy { $0.isSelected }
                                return DuplicateAssetGroup(isSelectedAll: allSelected, assets: assets)
                            }
                            self.groupedPhotos = videoGroups
                            
                            self.totalPhotos = "\(self.groupedPhotos.flatMap { $0.assets }.count)"
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        } else {
                            self.updateVidoPanel()
                            timer.invalidate()
                            self.screenState = self.groupedPhotos.isEmpty ? .allClean : .content
                        }
                    }
                }
            } else {
                if groupedPhotos.isEmpty {
                    screenState = .allClean
                } else {
                    screenState = .content
                }
                self.isAnalyzing = false
            }
            
        default:
            break
        }
    }
    
    private func updatePhotosPanel() {
        let status = assetService.getScanStatus()
        let photoGroups: [DuplicateAssetGroup] = status.groups.map { group in
            let photoAssets = group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
            let allSelected = photoAssets.allSatisfy { $0.isSelected }
            return DuplicateAssetGroup(isSelectedAll: allSelected, assets: photoAssets)
        }
        self.groupedPhotos = photoGroups
    }
    
    private func updateVidoPanel() {
        let status = videoManagementService.getVideoDuplicatesStatus()
        let photoGroups: [DuplicateAssetGroup] = status.groups.map { group in
            let assets = group.assets.map { PhotoAsset(isSelected: false, asset: $0.asset) }
            let allSelected = assets.allSatisfy { $0.isSelected }
            return DuplicateAssetGroup(isSelectedAll: allSelected, assets: assets)
        }
        self.groupedPhotos = photoGroups
    }
    
    // MARK: - Таймер анализа (примерно для визуализации прогресса)
    
    private func startAnalysisTimer() {
        analysisTimer?.invalidate()
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Если нужно анимировать локальный прогресс
            // self?.analysisProgress += 1
            // self?.timerText = "\(self?.analysisProgress ?? 0)%"
        }
    }
    
    private func finishAnalysis() {
        analysisTimer?.invalidate()
        analysisProgress = 100
        timerText = "100%"
        isAnalyzing = false
        
        if groupedPhotos.isEmpty {
            screenState = .allClean
        } else {
            screenState = .content
        }
    }
    
    /// Объединяем новые группы с имеющимися, чтобы не потерять isSelected
    private func mergeGroupedPhotos(newGroups: [DuplicateAssetGroup]) -> [DuplicateAssetGroup] {
        return newGroups.map { newGroup in
            // Для каждого PhotoAsset в этой группе ищем, нет ли такого же (по localIdentifier) в старых
            let updatedAssets = newGroup.assets.map { newAsset in
                if let oldAsset = groupedPhotos
                    .flatMap({ $0.assets })
                    .first(where: { $0.asset.localIdentifier == newAsset.asset.localIdentifier }) {
                    
                    // Сохраняем старое состояние isSelected
                    return PhotoAsset(isSelected: oldAsset.isSelected, asset: newAsset.asset)
                } else {
                    return newAsset
                }
            }
            // Пересчитываем isSelectedAll
            let allSelected = updatedAssets.allSatisfy { $0.isSelected }
            return DuplicateAssetGroup(isSelectedAll: allSelected, assets: updatedAssets)
        }
    }
    
    // MARK: - Экранные записи
    
    private func getScreenRecordsGroups() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let status = self.videoManagementService.getScreenRecordingsStatus()
            
            self.screenState = .content
            self.isAnalyzing = status.isScanning
            
            self.screenshots = status.groups.map {
                let screenRecordsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                let allSelected = screenRecordsAsset.allSatisfy { $0.isSelected }
                return ScreenshotsAsset(title: $0.title, isSelectedAll: allSelected, groupAsset: screenRecordsAsset)
            }
            self.groupedPhotos = status.groups.map {
                var screenRecordsAsset = $0.groupAsset.map { PhotoAsset(isSelected: true, asset: $0.asset) }
                let allSelected = screenRecordsAsset.allSatisfy { $0.isSelected }
                
                return DuplicateAssetGroup(isSelectedAll: allSelected, assets: screenRecordsAsset)
            }
            
            self.totalPhotos = "\(self.groupedPhotos.flatMap { $0.assets }.count)"

            checkStatusForSeselectAll()
            recalculateSelectedSize()
            isDataLoadedAndShow = true

            if !status.isScanning {
                self.isAnalyzing = false
            } else {
                // Повторяем опрос, если ещё не завершён
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.getScreenRecordsGroups()
                }
            }
        }
    }
    
    
    private func setDefaultDataToBottomButton() {
        switch self.type {
        case .photos:
            self.selectedPhotos = "DELETE PHOTOS"
            self.selectedSizeInGB = ""
        case .screenshots:
            self.selectedPhotos = "DELETE SCREENSHOTS"
            self.selectedSizeInGB = ""
        case .video:
            self.selectedPhotos = "DELETE VIDEO"
            self.selectedSizeInGB = ""
        case .screenRecords:
            self.selectedPhotos = "DELETE RECORDINGS"
            self.selectedSizeInGB = ""
        }
    }
}
