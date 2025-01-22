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

final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties

    @Published var isHaveSubscription = true //UserDefaultsService.isHaveSubscribe
    
    /// Header
    @Published var totalSpaceGB: Double = 0.0
    @Published var freeSpaceGB: Double = 0.0
    @Published var progress: CGFloat = 0.0

    /// Photo and video
    @Published var isPhonoAndVideoLoaderActive: Bool = false
    @Published var isPhonoAndVideoAvailable: Bool = false
    @Published var phonoAndVideoGB: Double = 0.0
    @Published var phonoAndVideoGBText: String = ""

    /// Сontacts
    @Published var isСontactsLoaderActive: Bool = false
    @Published var isСontactsAvailable: Bool = false
    @Published var contactsCount: Int = 0
    @Published var contactsText: String = ""
    @Published var duplicateContactsCount: Int = 0

    /// Calendar
    @Published var isCalendarLoaderActive: Bool = false
    @Published var isCalendarAvailable: Bool = false
    @Published var сalendarText: String = ""


    // MARK: - Private Properties

    private let service: HomeService
    private let router: HomeRouter

    private let photoVideoManager = PhotoVideoManager.shared
    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()

    // MARK: - Init

    init(
        service: HomeService,
        router: HomeRouter
    ) {
        self.service = service
        self.router = router
                
        self.isPhonoAndVideoLoaderActive = true
//        self.isСontactsLoaderActive = true
//        self.isCalendarLoaderActive = true
        
        calculateStorage()
        requestPhotoLibraryAccess()
    }
    
    // MARK: - Public Methods
    
    func didTapPhotoAndVideo() {
        guard isPhonoAndVideoAvailable else {
            showSettingsAlert("To review similar photos and videos, please grant \"Photo Manager\" permission to access your gallery.")
            return
        }
        router.openSimilarPhotos()
    }
    
    func didTapContact() {
        guard isСontactsAvailable else {
            showSettingsAlert("No access to Contacts. Please enable this in your settings.")
            return
        }
        
        print("action didTapContact")
    }

    func didTapCalendar() {
        guard isCalendarAvailable else {
            showSettingsAlert("No access to Calendar. Please enable it in your settings to continue.")
            return
        }
        
        print("action didTapCalendar")
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

    // MARK: - Calculate Storage

    private func calculateStorage() {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSpace = attributes[.systemSize] as? Int64,
               let freeSpace = attributes[.systemFreeSize] as? Int64 {
                
                // Конвертация в десятичные GB (как указывает производитель)
                let totalSpaceDecimalGB = Double(totalSpace) / 1_000_000_000
                let freeSpaceDecimalGB = Double(freeSpace) / 1_000_000_000
                
                // Сохранение в бинарных GB для прогресса
                let totalSpaceBinaryGB = Double(totalSpace) / 1_073_741_824
                let freeSpaceBinaryGB = Double(freeSpace) / 1_073_741_824
                
                self.totalSpaceGB = totalSpaceBinaryGB
                self.freeSpaceGB = freeSpaceBinaryGB
                self.progress = CGFloat(1 - freeSpaceBinaryGB / totalSpaceBinaryGB)
                
                // TODO: Claer it
                print("Total Space (Decimal GB): \(totalSpaceDecimalGB)")
                print("Total Space (Binary GB): \(totalSpaceBinaryGB)")
            }
        } catch {
            print("Error retrieving storage information: \(error.localizedDescription)")
        }
    }

    // MARK: - Photo Video
    
    private func requestPhotoLibraryAccess() {
        self.isPhonoAndVideoLoaderActive = true
        photoVideoManager.requestAuthorization { [weak self] granted in
            guard granted else {
                print("Access denied to photo library.")
                self?.isPhonoAndVideoAvailable = false
                self?.isPhonoAndVideoLoaderActive = false
                self?.showSettingsAlert("To review similar photos and videos, please grant \"Photo Manager\" permission to access your gallery.")
                return
            }

            self?.photoVideoManager.calculatePhotoAndVideoStorageUsage { [weak self] photoGB, videoGB in
                self?.phonoAndVideoGB = photoGB + videoGB
                self?.phonoAndVideoGBText = String(format: "%.1f", self?.phonoAndVideoGB ?? 0) + " GB"
                self?.isPhonoAndVideoAvailable = true
                self?.isPhonoAndVideoLoaderActive = false
                print("Photos: \(photoGB) GB, Videos: \(videoGB) GB")
            }
        }
    }

    // MARK: - Contacts
    
    private func requestContactsAccess() {
        self.isСontactsLoaderActive = true
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            guard granted, error == nil else {
                print("Access denied to contacts.")
                self?.isСontactsLoaderActive = false
                self?.isСontactsAvailable = false
                self?.showSettingsAlert("No access to Contacts. Please enable this in your settings.")
                return
            }
            
            self?.checkDuplicateContacts()
        }
    }

    func checkDuplicateContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contactsSet = Set<String>()
        var duplicateCount = 0
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                let key = "\(contact.givenName) \(contact.familyName) \(contact.phoneNumbers.first?.value.stringValue ?? "")"
                
                if contactsSet.contains(key) {
                    duplicateCount += 1
                } else {
                    contactsSet.insert(key)
                }
            }
            DispatchQueue.main.async {
                self.duplicateContactsCount = duplicateCount
                self.contactsCount = contactsSet.count
                self.contactsText = "\(duplicateCount)"
                self.isСontactsAvailable = true
                self.isСontactsLoaderActive = false
                
                self.clearOldCalendarEvents()
            }
        } catch {
            DispatchQueue.main.async {
                self.isСontactsAvailable = false
                self.isСontactsLoaderActive = false
                
                self.clearOldCalendarEvents()
            }
            print("Error fetching contacts: \(error.localizedDescription)")
        }
    }

    
    // MARK: - Calendar

    func clearOldCalendarEvents() {
        self.isCalendarLoaderActive = true

        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard granted, error == nil else {
                DispatchQueue.main.async {
                    self?.isCalendarLoaderActive = false
                    self?.isCalendarAvailable = false
                    self?.showSettingsAlert("No access to Calendar. Please enable it in your settings to continue.")
                }
                return
            }
            
            // Fetch and delete old events
//            self?.deleteOldEvents()
        }
    }

    private func deleteOldEvents() {
        // Define the time range (up to yesterday)
        let calendars = eventStore.calendars(for: .event)
        
        let startDate = Date.distantPast // Start from the earliest date
        let endDate = Calendar.current.startOfDay(for: Date()) // Start of today (exclusive)
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        // Delete events
        do {
            for event in events {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }
            // Commit changes
            try eventStore.commit()
            DispatchQueue.main.async { [weak self] in
                self?.isCalendarAvailable = true
                self?.isCalendarLoaderActive = false
//                completion(true, nil)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isCalendarAvailable = false
                self?.isCalendarLoaderActive = false
//                completion(false, error)
            }
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
}
