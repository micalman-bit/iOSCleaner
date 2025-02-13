//
//  ContactsViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import Foundation
import Contacts

enum ScreenState {
    case loading
    case content
    case allClean
}

final class ContactsViewModel: ObservableObject {
 
    // MARK: - Published Properties

    @Published var duplicateCount: String = ""
    @Published var groupCount: String = ""
    
    @Published var progressLoading: String = "0%"
    
    @Published var isEnabledButton: Bool = false
    
    @Published var duplicates: [ContactDuplicateGroup] = []
    @Published var screenState: ScreenState = .loading
    
    @Published var isEnabledSeselectAll: Bool = false

    // MARK: - Private Properties

    private let service: ContactsService
    private let router: ContactsRouter
    private let contactManager = ContactManager.shared
    
    // MARK: - Init

    init(
        service: ContactsService,
        router: ContactsRouter
    ) {
        self.service = service
        self.router = router
        
        getDuplicateContactGroups()
    }
    
    // MARK: - Public Methods

    func dismiss() {
        router.dismiss()
    }

    func setSelectToItem(_ item: ContactDuplicateItem) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.duplicates.indices {
                if let itemIndex = self.duplicates[index].contacts.firstIndex(where: { $0.id == item.id }) {
                    self.duplicates[index].contacts[itemIndex].isSelect.toggle()
                    break
                }
            }
            
            let allSelected = self.duplicates
                .flatMap { $0.contacts }
                .allSatisfy { $0.isSelect }
            
            if allSelected {
                isEnabledSeselectAll = true
            } else {
                isEnabledSeselectAll = false
            }

            updateDuplicateCount()
        }
    }
    
    func setDeselectToItems(_ items: [ContactDuplicateItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.duplicates.indices {
                self.duplicates[index].isSelect.toggle()
                for item in items {
                    if let itemIndex = self.duplicates[index].contacts.firstIndex(where: { $0.id == item.id }) {
                        self.duplicates[index].contacts[itemIndex].isSelect = self.duplicates[index].isSelect//
                    }
                }
            }
            
            let allSelected = self.duplicates
                .flatMap { $0.contacts }
                .allSatisfy { $0.isSelect }
            
            if allSelected {
                isEnabledSeselectAll = true
            } else {
                isEnabledSeselectAll = false
            }

            updateDuplicateCount()
        }
    }
    
    func setSelectToAllItems() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.duplicates.indices {
                self.duplicates[index].isSelect.toggle()
                for itemIndex in self.duplicates[index].contacts.indices {
                    self.duplicates[index].contacts[itemIndex].isSelect = self.duplicates[index].isSelect
                    isEnabledSeselectAll = self.duplicates[index].isSelect
                }
            }
            
            updateDuplicateCount()
        }
    }
    
    func mergeContacts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            for groupIndex in self.duplicates.indices {
                guard self.duplicates[groupIndex].contacts.count > 1 else { continue }
                
                let remainingContacts = self.duplicates[groupIndex].contacts.dropFirst()
                
                let selectedContacts = remainingContacts.filter { $0.isSelect }
                
                for contact in selectedContacts {
                    self.contactManager.deleteContact(contact.item)
                }
                
                self.duplicates[groupIndex].contacts.removeAll { contact in
                    remainingContacts.contains(where: { $0.id == contact.id }) && contact.isSelect
                }
            }

            self.duplicates.removeAll(where: { $0.contacts.count <= 1 })
            self.updateDuplicateCount()
            
            self.contactManager.duplicateGroups = duplicates
            
            NotificationCenter.default.post(
                name: .updateCalendarCounter,
                object: nil,
                userInfo: ["counter": duplicates.count]
            )

            if self.duplicates.isEmpty {
                self.screenState = .allClean
            }
        }
    }

    // MARK: - Private Methods
    
    private func updateDuplicateCount() {
        let totalItems = duplicates.reduce(0) { $0 + $1.contacts.count }
        duplicateCount = "\(totalItems) Duplicate"
        
//        let selecteditexrms
        let selectedGroupsCount = duplicates.filter { group in
            group.contacts.dropFirst().contains(where: { $0.isSelect })
        }.count
        
        if selectedGroupsCount > 0 {
            groupCount = "MERGE \(selectedGroupsCount) CONTACTS"
            isEnabledButton = true
        } else {
            groupCount = "MERGE CONTACTS"
            isEnabledButton = false
        }
    }

    private func getDuplicateContactGroups() {
        let status = contactManager.getDuplicateSearchStatus()

        if !status.isScanning {
            DispatchQueue.main.async { [weak self] in
                if !status.duplicateGroups.isEmpty {
                    self?.duplicates = status.duplicateGroups
                    self?.updateDuplicateCount()
                    self?.screenState = .content
                } else {
                    self?.screenState = .allClean
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.progressLoading = "\(Int(status.progress * 100))%"
            }
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.getDuplicateContactGroups()
            }
        }
    }
}

