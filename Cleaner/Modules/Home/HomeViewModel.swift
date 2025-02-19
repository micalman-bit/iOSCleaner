//
//  HomeViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI
import Contacts
import EventKit
import UIKit
import Photos

public enum HomeButtonType {
    case photoVideo
    case contact
    case calendar
}

final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var isHaveSubscription = UserDefaultsService.isHaveSubscribe
    
    /// Header
    @Published var totalSpaceGB: Double = 0.0
    @Published var freeSpaceGB: Double = 0.0
    @Published var progress: CGFloat = 0.0

    /// Photo and video
    @Published var isPhonoAndVideoLoaderActive: Bool = true
    @Published var phonoAndVideoGB: Double = 0.0
    @Published var phonoAndVideoGBText: String = ""
    @Published var totalFilesCount: String = ""
    @Published var isPhonoAndVideoAvailable: Bool = false {
        didSet {
            if isPhonoAndVideoAvailable {
                calculatePhotoAndVideoStorage()
            }
        }
    }

    /// Сontacts
    @Published var isСontactsLoaderActive: Bool = true
    @Published var isСontactsAvailable: Bool
    @Published var contactsCount: Int = 0
    @Published var contactsText: String = ""
    @Published var duplicateContactsCount: Int = 0

    /// Calendar
    @Published var isCalendarLoaderActive: Bool = true
    @Published var isCalendarAvailable: Bool = false
    @Published var сalendarText: String = ""

    @Published var konamiCodeCounter: Int = 0 {
        didSet {
            if konamiCodeCounter >= 5 {
                konamiCodeCounter = 0
                UserDefaultsService.isHaveSubscribe.toggle()
                isHaveSubscription.toggle()
            } 
        }
    }


    // MARK: - Private Properties

    private let service: HomeService
    private let router: HomeRouter

    private let photoVideoManager = PhotoVideoManager.shared
    private let contactManager = ContactManager.shared
    private let calendarManager = CalendarManager.shared
    private var assetService = AssetManagementService.shared
    private let videoManagementService = VideoManagementService.shared

    private var contactsUpdateTimer: Timer?
    private var calendarUpdateTimer: Timer?
    private var totalSizeTimer: Timer?

    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()

    // MARK: - Init

    init(
        service: HomeService,
        router: HomeRouter
    ) {
        self.service = service
        self.router = router
        
        self.isСontactsAvailable = UserDefaultsService.isGetContactsAccess
        self.isCalendarAvailable = UserDefaultsService.isGetCalendarAccess
        
        calculatePhotoAndVideoStorage()
        requestAccess()
        checkAccess()
    }
        
    // MARK: - Public Methods
    
    func checkAccess() {
        if contactManager.checkAuthorizationStatus() {
            isСontactsAvailable = true
            UserDefaultsService.isGetContactsAccess = true
            contactManager.startDuplicateSearch()
            fetchAndAnalyzeContacts()
        } else {
            isСontactsLoaderActive = false
            isСontactsAvailable = false
            UserDefaultsService.isGetContactsAccess = false
        }
        
        if calendarManager.checkAuthorizationStatus() {
            isCalendarAvailable = true
            UserDefaultsService.isGetCalendarAccess = true
            calendarManager.searchEventsInBackground()
            fetchAndAnalyzeCalendar()
        } else {
            isCalendarLoaderActive = false
            isCalendarAvailable = false
            UserDefaultsService.isGetCalendarAccess = false
        }
    }
    
    func didTapPhotoAndVideo() {
        if photoVideoManager.checkAuthorizationStatus() {
            router.openSimilarPhotos(screenType: .photosAndVideos)
        } else {
            showSettingsAlert("To review similar photos and videos, please grant \"Photo Manager\" permission to access your gallery.")
        }
    }

    func didTapSmartAnalize() {        
        router.openSimilarPhotos(screenType: .analyzeStorage)
    }
    
    func didTapContact() {
        contactManager.requestContactsAccess { [weak self] granted in
            if granted {
                self?.router.openContacts()
            } else {
                self?.showSettingsAlert("No access to Contacts. Please enable this in your settings.")
            }
        }
    }

    func didTapCalendar() {
        calendarManager.requestCalendarAccess { [weak self] granted in
            if granted {
                self?.router.openCalendar()
            } else {
                self?.showSettingsAlert("No access to Calendar. Please enable it in your settings to continue.")
            }
        }
    }

    func didTapSetting() {
        router.openSettings()
    }
    
    func didTapSubscription() {
        UserDefaultsService.isHaveSubscribe.toggle()
        isHaveSubscription.toggle()
    }
    
    func getSmile() -> String {
        switch progress {
        case 0.0...0.49: return "😎"
        case 0.5...0.69: return "🙂"
        case 0.7...0.89: return "☹"
        case 0.9...1: return "😱"
        default: return ""
        }
    }

    func getLineColor() -> Color {
        switch progress {
        case 0.0...0.49: return Color.Borders.green
        case 0.5...0.69: return Color.Borders.lightGreen
        case 0.7...0.89: return Color.Borders.orange
        case 0.9...1: return Color.Borders.red
        default: return Color.Borders.green
        }
    }

    func updateContactCounter(_ value: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.contactsText = String(value)
        }
    }
    
    func updateCalendarCounter(_ value: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.сalendarText = String(value)
        }
    }

    // MARK: - Private Methods
    
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
    
    private func fetchAndAnalyzeContacts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.contactsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                let status = contactManager.getDuplicateSearchStatus()
                
                if !status.isScanning {
                    contactsText = "\(status.duplicateGroups.count)"
                    isСontactsLoaderActive = false
                    timer.invalidate()
                }
            })
        }
    }

    private func fetchAndAnalyzeCalendar() {
        calendarManager.getEventsGroups { [weak self] eventsGroup, isSearchingEvents in
            if isSearchingEvents {
                self?.isCalendarLoaderActive = true
                self?.calendarUpdateTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                    
                    self?.fetchAndAnalyzeCalendar()
                    if isSearchingEvents == false {
                        timer.invalidate()
                    }
                })

            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.isCalendarLoaderActive = false
                    let totalItems = eventsGroup?.reduce(0) { $0 + $1.events.count } ?? 0
                    self?.сalendarText = "\(totalItems)"
                }
            }
        }
    }
    

    private func requestAccess() {
        if photoVideoManager.checkAuthorizationStatus() {
            isPhonoAndVideoAvailable = true
            assetService.requestGalleryAccessAndStartScan()
            videoManagementService.startDuplicateScan()
            calculateTotalSizeFromServices()
        } else {
            photoVideoManager.requestAuthorization { [weak self] granted in
                guard let self else { return }
                if granted {
                    isPhonoAndVideoAvailable = true
                    assetService.requestGalleryAccessAndStartScan()
                    videoManagementService.startDuplicateScan()
                } else {
                    self.isPhonoAndVideoAvailable = false
                    self.showSettingsAlert("To review similar photos and videos, please grant \"Photo Manager\" permission to access your gallery.")
                }
            }
        }
    }
    
    private func calculateTotalSizeFromServices() {
        let photoStatus = assetService.getScanStatus()
        let videoStatus = videoManagementService.getVideoDuplicatesStatus()
        let screenRecordStatus = videoManagementService.getScreenRecordingsStatus()

        let isScanning = photoStatus.isScanning || videoStatus.isScanning || screenRecordStatus.isScanning

        assetService.fetchScreenshotsGroupedByMonth { [weak self] screenshotGroups in
            guard let self = self else { return }
            
            let screenshots = screenshotGroups.flatMap { $0.groupAsset }
            let photos = photoStatus.groups.flatMap { $0.assets }
            let videos = videoStatus.groups.flatMap { $0.assets }
            let screenRecords = screenRecordStatus.groups.flatMap { $0.groupAsset }
            
            let allAssets = photos + videos + screenshots + screenRecords
            
            self.calculateTotalBytes(for: allAssets) { totalBytes in
                let formattedSize = self.formatSize(totalBytes)
                if isScanning {
                    self.phonoAndVideoGBText = "\(formattedSize)"
                    self.isPhonoAndVideoLoaderActive = false
                    
                    self.totalSizeTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { _ in
                        self.calculateTotalSizeFromServices()
                    }
                    
                } else {
                    self.phonoAndVideoGBText = "\(formattedSize)"
                    self.isPhonoAndVideoLoaderActive = false
                    self.totalSizeTimer?.invalidate()
                    print("Финальный объём найденных медиа: \(formattedSize)")
                }
            }
        }
    }

    private func calculateTotalBytes(for assets: [PhotoAsset], completion: @escaping (Int64) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalSize: Int64 = 0
            for asset in assets {
                if let resource = PHAssetResource.assetResources(for: asset.asset).first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += fileSize
                }
            }
            DispatchQueue.main.async {
                completion(totalSize)
            }
        }
    }
    
    private func calculatePhotoAndVideoStorage() {
        let fileManager = FileManager.default
        let homeDirectory = NSHomeDirectory()
        
        var totalFilesCount = 0
        var totalFoldersCount = 0

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: homeDirectory)
            if let totalSpace = attributes[.systemSize] as? Int64,
               let freeSpace = attributes[.systemFreeSize] as? Int64 {

                let totalSpaceFormatted = formatSize(totalSpace)
                let freeSpaceFormatted = formatSize(freeSpace)

                // Сохранение в бинарных GB для прогресса
                let totalSpaceBinaryGB = Double(totalSpace) / 1_073_741_824
                let freeSpaceBinaryGB = Double(freeSpace) / 1_073_741_824

                self.totalSpaceGB = totalSpaceBinaryGB
                self.freeSpaceGB = freeSpaceBinaryGB
                self.progress = CGFloat(1 - freeSpaceBinaryGB / totalSpaceBinaryGB)

                // Подсчет количества файлов и папок
                if let enumerator = fileManager.enumerator(atPath: homeDirectory) {
                    for case let item as String in enumerator {
                        let fullPath = (homeDirectory as NSString).appendingPathComponent(item)
                        var isDirectory: ObjCBool = false
                        
                        if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                            if isDirectory.boolValue {
                                totalFoldersCount += 1
                            } else {
                                totalFilesCount += 1
                            }
                        }
                    }
                }
                self.totalFilesCount = String(format: "%.2f", totalFilesCount)
            }
        } catch {
            print("Error retrieving storage information: \(error.localizedDescription)")
        }
    }
    
    func formatSize(_ size: Int64) -> String {
        let kb = Double(size) / 1_024
        let mb = kb / 1_024
        let gb = mb / 1_024

        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.2f KB", kb)
        }
    }
}

