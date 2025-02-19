//
//  PhotosAndVideosViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import Photos
import Combine
import SwiftUI

enum PhotosAndVideosFromType {
    case analyzeStorage
    case photosAndVideos
}

enum AssetItemType {
    case screenshots
    case screenRecordings
    case similarPhotos
    case videoDuplicates
    case contactsDuplicates
    case calendarEvents
}

struct PhotosAndVideosLeftImageModel {
    let image: Image
    let size: CGFloat
}

struct PhotosAndVideosItemModel: Identifiable {
    let id: UUID = UUID()
    let leftTitle: String
    var letftImage: PhotosAndVideosLeftImageModel?
    var leftSubtitle: String
    var rightTitle: String?
    let rightImage: PhotosAndVideosLeftImageModel?
    var isLoading: Bool = false
    let type: AssetItemType
    let action: () -> Void
}

final class PhotosAndVideosViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var title: String
    
    @Published var listOfItems: [PhotosAndVideosItemModel] = []
    @Published var isAnalyzing: Bool = false
    @Published var timerText: String = "0%"
    @Published var analysisProgress: Double = 0.0

    // MARK: - Private Properties

    private let service: PhotosAndVideosService
    private let router: PhotosAndVideosRouter
    
    private let videoManagementService = VideoManagementService.shared
    private var assetService = AssetManagementService.shared
    private let contactManager = ContactManager.shared
    private let calendarManager = CalendarManager.shared

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
    
    private var contactsUpdateTimer: Timer?
    private var calendarUpdateTimer: Timer?
    
    private let screenType: PhotosAndVideosFromType

    // MARK: - Init

    init(
        service: PhotosAndVideosService,
        router: PhotosAndVideosRouter,
        screenType: PhotosAndVideosFromType
    ) {
        self.service = service
        self.router = router
        self.screenType = screenType
        
        switch screenType {
        case .photosAndVideos:
            title = "Photos & Videos"
        case .analyzeStorage:
            title = "Analyze storage"
        }

        self.listOfItems = self.configureBaseList(screenType)
        
        if screenType == .analyzeStorage {
            if !UserDefaultsService.isGetCalendarAccess {
                calendarManager.requestCalendarAccess { [weak self] isAvailable in
                    if isAvailable {
                        guard let self else { return }
                        self.contactManager.startDuplicateSearch()
                        self.updateListItem(
                            with: PhotosAndVideosItemModel(
                                leftTitle: "Calendar Events",
                                letftImage: .init(
                                    image: Image("circleCheck"),
                                    size: 24
                                ),
                                leftSubtitle: "0",
                                rightTitle: nil,
                                rightImage: .init(
                                    image: Image("arrow-right-s-line"),
                                    size: 24
                                ),
                                isLoading: true,
                                type: .calendarEvents,
                                action: self.didTapCalendar
                            )
                        )
                    }
                }
            } else {
                calendarManager.searchEventsInBackground()
            }
            
            if !UserDefaultsService.isGetContactsAccess {
                contactManager.requestContactsAccess { [weak self] isAvailable in
                    if isAvailable {
                        guard let self else { return }
                        self.contactManager.startDuplicateSearch()
                        self.updateListItem(
                            with: PhotosAndVideosItemModel(
                                leftTitle: "Contacts Duplicates",
                                letftImage: .init(
                                    image: Image("circleCheck"),
                                    size: 24
                                ),
                                leftSubtitle: "0",
                                rightTitle: nil,
                                rightImage: .init(
                                    image: Image("arrow-right-s-line"),
                                    size: 24
                                ),
                                isLoading: true,
                                type: .contactsDuplicates,
                                action: self.didTapContacts
                            )
                        )
                    }
                }
            } else {
                contactManager.startDuplicateSearch()
            }
        }

        loadAndAnalyzePhotos()
    }
    
    // MARK: - Public Methods
    
    func dismiss() {
        router.dismiss()
        assetService.listOfItems = self.listOfItems
        photosUpdateTimer?.invalidate()
        screenshotsUpdateTimer?.invalidate()
    }
    
    func updateContactCounter(_ value: Int) {
        let letftImage: PhotosAndVideosLeftImageModel = .init(
            image: Image("circleCheck"),
            size: 24
        )
        
        let newItem = PhotosAndVideosItemModel(
            leftTitle: "Contacts Duplicates",
            letftImage: letftImage,
            leftSubtitle: String(value),
            rightTitle: nil,
            rightImage: .init(
                image: Image("arrow-right-s-line"),
                size: 24
            ),
            isLoading: false,
            type: .contactsDuplicates,
            action: didTapContacts
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.updateListItem(with: newItem)
        }
    }
    
    func updateCalendarCounter(_ value: Int) {
        let letftImage: PhotosAndVideosLeftImageModel = .init(
            image: Image("circleCheck"),
            size: 24
        )
        
        let newItem = PhotosAndVideosItemModel(
            leftTitle: "Calendar Events",
            letftImage: letftImage,
            leftSubtitle: String(value),
            rightTitle: nil,
            rightImage: .init(
                image: Image("arrow-right-s-line"),
                size: 24
            ),
            isLoading: false,
            type: .calendarEvents,
            action: didTapCalendar
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.updateListItem(with: newItem)
        }
    }
    
    func didTapContacts() {
        if UserDefaultsService.isGetContactsAccess {
            router.openContacts()
        } else {
            showSettingsAlert("No access to Contacts. Please enable this in your settings.")
        }
    }

    // MARK: - Photo Analysis
    
    private func loadAndAnalyzePhotos() {
        groupedPhotos = []
        
        updatePhotosPanel()
        analyzeScreenshots()
        
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
    
    private func updatePhotosPanel(isByMyself: Bool = false) {
        let status = assetService.getScanStatus()
        let groups = status.groups
        let arrayOfPhotoAssets = groups.map { $0.assets }
        
        groupedPhotos = arrayOfPhotoAssets
        
        var letftImage: PhotosAndVideosLeftImageModel?
        switch self.screenType {
        case .photosAndVideos:
            letftImage = .init(
                image: Image("folders_line"),
                size: 40
            )
        case .analyzeStorage:
            letftImage = .init(
                image: Image("circleCheck"),
                size: 24
            )
        }

        let allPhotoAssets: [PhotoAsset]
        if isByMyself {
            allPhotoAssets = groupedPhotos.flatMap { $0 }
        } else {
            allPhotoAssets = arrayOfPhotoAssets.flatMap { $0 }
        }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(allPhotoAssets) { [weak self] formattedSize in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let countString = "\(allPhotoAssets.count)"
                let newItem = PhotosAndVideosItemModel(
                    leftTitle: "Similar Photos",
                    letftImage: letftImage,
                    leftSubtitle: countString,
                    rightTitle: formattedSize,
                    rightImage: .init(
                        image: Image("arrow-right-s-line"),
                        size: 24
                    ),
                    isLoading: status.isScanning,
                    type: .similarPhotos,
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.openSimilarAsset(
                            photoOrVideo: self.groupedPhotos,
                            type: .photos,
                            backTapAction: { [weak self] photAsset, screenshotAsset, isDataLoadedAndShow in
                                if let photAsset, isDataLoadedAndShow {
                                    self?.assetService.duplicatePhotoGroups = photAsset
                                    self?.groupedPhotos = photAsset.compactMap({ $0.assets })
                                    self?.updatePhotosPanel(isByMyself: true)
                                }
                            }
                        )
                    }
                )
                self.updateListItem(with: newItem)
            }
        }
    }

    // MARK: - Screenshots Analysis

    private func analyzeScreenshots() {
//        updateScreenshotsPanel { newGroups in
//            self.lastScreenshotsSummary = newGroups.map { ($0.title, $0.groupAsset.count) }
//        }
        fetchAndAnalyzeVideos()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.screenshotsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                self.updateScreenshotsPanel { newGroups in
                    let newSummary = newGroups.map { ($0.title, $0.groupAsset.count) }
                    if newSummary.elementsEqual(self.lastScreenshotsSummary, by: { (lhs, rhs) in
                        return lhs.0 == rhs.0 && lhs.1 == rhs.1
                    }) {
                        timer.invalidate()
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.groupedScreenshots = screenshots
                let screenshotAssets = screenshots.flatMap { $0.groupAsset }
                PhotoVideoManager.shared.calculateStorageUsageForAssets(screenshotAssets) { formattedSize in
                        
                        var letftImage: PhotosAndVideosLeftImageModel?
                        switch self.screenType {
                        case .photosAndVideos:
                            letftImage = .init(
                                image: Image("file_image"),
                                size: 40
                            )
                        case .analyzeStorage:
                            letftImage = .init(
                                image: Image("circleCheck"),
                                size: 24
                            )
                        }

                        let newItem = PhotosAndVideosItemModel(
                            leftTitle: "Screenshots",
                            letftImage: letftImage,
                            leftSubtitle: "\(screenshotAssets.count)",
                            rightTitle: formattedSize,
                            rightImage: .init(
                                image: Image("arrow-right-s-line"),
                                size: 24
                            ),
                            type: .screenshots,
                            action: { [weak self] in
                                self?.openSimilarAsset(
                                    screenshotsOrRecording: screenshots,
                                    type: .screenshots,
                                    backTapAction: { photAsset, screenshotAsset, isDataLoadedAndShow in
                                        if let screenshotAsset, isDataLoadedAndShow {
                                            self?.assetService.screenshotsAssets = screenshotAsset
                                            self?.groupedScreenshots = screenshotAsset
                                            self?.updateScreenshotsPanel()
                                        }
                                    }
                                )
                            }
                        )
                    self.updateListItem(with: newItem)
                    completion?(screenshots)
                }
            }
        }
    }
    
    // MARK: - Videos Analysis
    
    /// Запускает анализ видео с промежуточными обновлениями.
    /// При каждом обнаружении новой группы дубликатов обновляется плашка "Video Duplicates".
    /// После завершения анализа видео запускается анализ экранных записей.
    private func fetchAndAnalyzeVideos() {

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
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(videoAssets) { [weak self] formattedSize in
            guard let self else { return }
            
            var letftImage: PhotosAndVideosLeftImageModel?
            switch self.screenType {
            case .photosAndVideos:
                letftImage = .init(
                    image: Image("phone_camera_line_2"),
                    size: 40
                )
            case .analyzeStorage:
                letftImage = .init(
                    image: Image("circleCheck"),
                    size: 24
                )
            }

            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Video Duplicates",
                letftImage: letftImage,
                leftSubtitle: "\(videoAssets.count)",
                rightTitle: formattedSize,
                rightImage: .init(
                    image: Image("arrow-right-s-line"),
                    size: 24
                ),
                isLoading: status.isScanning,
                type: .videoDuplicates,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.openSimilarAsset(
                        photoOrVideo: self.groupedVideo,
                        type: .video,
                        backTapAction: { [weak self] photAsset, screenshotAsset, isDataLoadedAndShow in
                            if let photAsset, isDataLoadedAndShow {
                                self?.videoManagementService.cachedVideoDuplicates = photAsset
                                self?.groupedVideo = photAsset.map { $0.assets }
                                self?.updateVideosPanel()
                            }
                        }
                    )
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
        
        if screenType == .analyzeStorage, UserDefaultsService.isGetContactsAccess {
            fetchAndAnalyzeContacts()
        }
        
        self.groupedScreenRecords = arrayOfScreenRecordingsAssets
        let groupedScreenAssets = self.groupedScreenRecords.flatMap { $0.groupAsset }
        
        PhotoVideoManager.shared.calculateStorageUsageForAssets(groupedScreenAssets) { [weak self] formattedSize in
            guard let self else { return }
            
            var letftImage: PhotosAndVideosLeftImageModel?
            switch self.screenType {
            case .photosAndVideos:
                letftImage = .init(
                    image: Image("phone_camera_line_1"),
                    size: 40
                )
            case .analyzeStorage:
                letftImage = .init(
                    image: Image("circleCheck"),
                    size: 24
                )
            }

            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Screen recordings",
                letftImage: letftImage,
                leftSubtitle: "\(groupedScreenAssets.count)",
                rightTitle: formattedSize,
                rightImage: .init(
                    image: Image("arrow-right-s-line"),
                    size: 24
                ),
                isLoading: status.isScanning,
                type: .screenRecordings,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.openSimilarAsset(
                        photoOrVideo: self.groupedVideo,
                        type: .screenRecords,
                        backTapAction: { [weak self] photAsset, screenshotAsset, isDataLoadedAndShow in
                            if let screenshotAsset, isDataLoadedAndShow {
                                self?.videoManagementService.cachedScreenRecordings = screenshotAsset
                                self?.groupedScreenRecords = screenshotAsset
                                self?.updateSceenRecordsPanel()
                            }
                        }
                    )
                }
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        }
    }

    // MARK: - Contacts
    
    private func fetchAndAnalyzeContacts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.contactsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let status = contactManager.getDuplicateSearchStatus()
                
                self.updateContactsPanel()
                
                if !status.isScanning {
                    self.updateContactsPanel()
                    timer.invalidate()
                }
            })
        }
    }
    
    private func updateContactsPanel() {
        if UserDefaultsService.isGetContactsAccess {
            let status = contactManager.getDuplicateSearchStatus()
            let groups = status.duplicateGroups
            
            fetchAndAnalyzeCalendar()
            
            var letftImage: PhotosAndVideosLeftImageModel?
            switch self.screenType {
            case .photosAndVideos:
                letftImage = .init(
                    image: Image("phone_camera_line_1"),
                    size: 40
                )
            case .analyzeStorage:
                letftImage = .init(
                    image: Image("circleCheck"),
                    size: 24
                )
            }
            
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Contacts Duplicates",
                letftImage: letftImage,
                leftSubtitle: "\(groups.count)",
                rightTitle: nil,
                rightImage: .init(
                    image: Image("arrow-right-s-line"),
                    size: 24
                ),
                isLoading: status.isScanning,
                type: .contactsDuplicates,
                action: didTapContacts
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        } else {
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Contacts Duplicates",
                letftImage: .init(
                    image: Image("circleDesable"),
                    size: 24
                ),
                leftSubtitle: "Need access, click to allow",
                rightTitle: nil,
                rightImage: .init(
                    image: Image("arrow-right-s-line"),
                    size: 24
                ),
                isLoading: false,
                type: .contactsDuplicates,
                action: didTapContacts
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }

        }
    }

    
    // MARK: - Calendar

    private func fetchAndAnalyzeCalendar() {
        guard UserDefaultsService.isGetCalendarAccess else {
            self.updateCalendarPanel(eventsGroup: nil, isScaning: false)
            return
        }
        
        calendarManager.getEventsGroups { [weak self] eventsGroup, isScanning in
            DispatchQueue.main.async { [weak self] in
                self?.updateCalendarPanel(eventsGroup: eventsGroup, isScaning: isScanning)
            }
            
            if isScanning {
                self?.calendarUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                    
                    self?.fetchAndAnalyzeCalendar()
                    if isScanning == false {
                        timer.invalidate()
                    }
                })
            }
        }
    }
    
    private func updateCalendarPanel(eventsGroup: [EventsGroup]?, isScaning: Bool) {
        if UserDefaultsService.isGetCalendarAccess {
            let leftSubtitle: String
            if let eventsGroup {
                leftSubtitle = "\(eventsGroup.count)"
            } else {
                leftSubtitle = "0"
            }
            
            let letftImage: PhotosAndVideosLeftImageModel = .init(
                image: Image("circleCheck"),
                size: 24
            )
            
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Calendar Events",
                letftImage: letftImage,
                leftSubtitle: leftSubtitle,
                rightTitle: nil,
                rightImage: .init(
                    image: Image("arrow-right-s-line"),
                    size: 24
                ),
                isLoading: isScaning,
                type: .calendarEvents,
                action: didTapCalendar
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        } else {
            let newItem = PhotosAndVideosItemModel(
                leftTitle: "Calendar Events",
                letftImage: .init(
                    image: Image("circleDesable"),
                    size: 24
                ),
                leftSubtitle: "Need access, click to allow",
                rightTitle: nil,
                rightImage: .init(
                    image: Image("lock_key"),
                    size: 24
                ),
                isLoading: false,
                type: .calendarEvents,
                action: didTapCalendar
            )
            DispatchQueue.main.async { [weak self] in
                self?.updateListItem(with: newItem)
            }
        }
    }

    func didTapCalendar() {
        if UserDefaultsService.isGetCalendarAccess {
            router.openCalendar()
        } else {
            showSettingsAlert("No access to Calendar. Please enable this in your settings.")
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
        type: SimilarAssetType,
        backTapAction: @escaping ([DuplicateAssetGroup]?, [ScreenshotsAsset]?, Bool) -> Void
    ) {
        router.openSimilarAsset(
            photoOrVideo: photoOrVideo,
            screenshotsOrRecording: screenshotsOrRecording,
            type: type,
            backTapAction: backTapAction
        )
    }
    
    // MARK: - Tiemer
    
    private func startProgressTimer() {
        // Сброс значений
        self.analysisProgress = 0.0
        self.timerText = "0%"
        self.isAnalyzing = false

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
    
    // MARK: - Base List
    private func configureBaseList(_ screenType: PhotosAndVideosFromType) -> [PhotosAndVideosItemModel] {
        if assetService.listOfItems.isEmpty {
            switch screenType {
            case .photosAndVideos:
                return [
                    PhotosAndVideosItemModel(
                        leftTitle: "Screenshots",
                        letftImage: .init(
                            image: Image("file_image"),
                            size: 40
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .screenshots,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Screen recordings",
                        letftImage: .init(
                            image: Image("phone_camera_line_1"),
                            size: 40
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .screenRecordings,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Similar Photos",
                        letftImage: .init(
                            image: Image("folders_line"),
                            size: 40
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .similarPhotos,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Video Duplicates",
                        letftImage: .init(
                            image: Image("phone_camera_line_2"),
                            size: 40
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .videoDuplicates,
                        action: { }
                    )
                ]
            case .analyzeStorage:
                return [
                    PhotosAndVideosItemModel(
                        leftTitle: "Screenshots",
                        letftImage: .init(
                            image: Image("circleCheck"),
                            size: 24
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        
                        isLoading: true,
                        type: .screenshots,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Screen recordings",
                        letftImage: .init(
                            image: Image("circleCheck"),
                            size: 24
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .screenRecordings,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Similar Photos",
                        letftImage: .init(
                            image: Image("circleCheck"),
                            size: 24
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .similarPhotos,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Video Duplicates",
                        letftImage: .init(
                            image: Image("circleCheck"),
                            size: 24
                        ),
                        leftSubtitle: "0",
                        rightTitle: "0 GB",
                        rightImage: .init(
                            image: Image("arrow-right-s-line"),
                            size: 24
                        ),
                        isLoading: true,
                        type: .videoDuplicates,
                        action: { }
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Contacts Duplicates",
                        letftImage: .init(
                            image: UserDefaultsService.isGetContactsAccess ? Image("circleCheck") : Image("circleDesable"),
                            size: 24
                        ),
                        leftSubtitle: UserDefaultsService.isGetContactsAccess ? "0" : "Need access, click to allow",
                        rightTitle: UserDefaultsService.isGetContactsAccess ? "0 GB" : nil,
                        rightImage: .init(
                            image: UserDefaultsService.isGetContactsAccess ? Image("arrow-right-s-line") : Image("lock_key"),
                            size: 24
                        ),
                        isLoading: UserDefaultsService.isGetContactsAccess ? true : false,
                        type: .contactsDuplicates,
                        action: didTapContacts
                    ),
                    PhotosAndVideosItemModel(
                        leftTitle: "Calendar Events",
                        letftImage: .init(
                            image: UserDefaultsService.isGetCalendarAccess ? Image("circleCheck") : Image("circleDesable"),
                            size: 24
                        ),
                        leftSubtitle: UserDefaultsService.isGetCalendarAccess ? "0" : "Need access, click to allow",
                        rightTitle: UserDefaultsService.isGetCalendarAccess ? "0 GB" : nil,
                        rightImage: .init(
                            image: UserDefaultsService.isGetCalendarAccess ? Image("arrow-right-s-line") : Image("lock_key"),
                            size: 24
                        ),
                        isLoading: UserDefaultsService.isGetCalendarAccess ? true : false,
                        type: .calendarEvents,
                        action: didTapCalendar
                    )
                ]
            }
        } else {
            var list = assetService.listOfItems.map { item in
                var newItem = item
                newItem.letftImage = .init(
                    image: getItemImageByType(item.type),
                    size: self.screenType == .analyzeStorage ? 24 : 40
                )
                return newItem
            }
            
            if screenType == .photosAndVideos {
                list.removeAll(where: { $0.type == .calendarEvents || $0.type == .contactsDuplicates})
            } else {
                if !list.contains(where: { $0.type == .contactsDuplicates }) {
                    list.append(
                        PhotosAndVideosItemModel(
                            leftTitle: "Contacts Duplicates",
                            letftImage: .init(
                                image: UserDefaultsService.isGetContactsAccess ? Image("circleCheck") : Image("circleDesable"),
                                size: 24
                            ),
                            leftSubtitle: UserDefaultsService.isGetContactsAccess ? "0" : "Need access, click to allow",
                            rightTitle: UserDefaultsService.isGetContactsAccess ? "0 GB" : nil,
                            rightImage: .init(
                                image: UserDefaultsService.isGetContactsAccess ? Image("arrow-right-s-line") : Image("lock_key"),
                                size: 24
                            ),
                            isLoading: UserDefaultsService.isGetContactsAccess ? true : false,
                            type: .contactsDuplicates,
                            action: didTapContacts
                        )
                    )
                }
                if !list.contains(where: { $0.type == .calendarEvents }) {
                    list.append(
                        PhotosAndVideosItemModel(
                            leftTitle: "Calendar Events",
                            letftImage: .init(
                                image: UserDefaultsService.isGetCalendarAccess ? Image("circleCheck") : Image("circleDesable"),
                                size: 24
                            ),
                            leftSubtitle: UserDefaultsService.isGetCalendarAccess ? "0" : "Need access, click to allow",
                            rightTitle: UserDefaultsService.isGetCalendarAccess ? "0 GB" : nil,
                            rightImage: .init(
                                image: UserDefaultsService.isGetCalendarAccess ? Image("arrow-right-s-line") : Image("lock_key"),
                                size: 24
                            ),
                            isLoading: UserDefaultsService.isGetCalendarAccess ? true : false,
                            type: .calendarEvents,
                            action: didTapCalendar
                        )
                    )
                }
            }

            return list
        }
    }
    
    private func getItemImageByType(_ type: AssetItemType) -> Image {
        if self.screenType == .analyzeStorage {
            return Image("circleCheck")
        } else {
            switch type {
            case .screenshots:
                return Image("file_image")
            case .screenRecordings:
                return Image("phone_camera_line_1")
            case .similarPhotos:
                return Image("folders_line")
            case .videoDuplicates:
                return Image("phone_camera_line_2")
            default:
                return Image("")
            }
        }
    }
    
    // MARK: - Settings Alert
    func showSettingsAlert(_ message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        let alert = UIAlertController(
            title: "Permission Required",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
            if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
        })

        DispatchQueue.main.async {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }
}
