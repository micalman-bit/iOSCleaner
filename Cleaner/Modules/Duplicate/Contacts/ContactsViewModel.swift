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
    
    @Published var isEnabledButton: Bool = false
    
    @Published var duplicates: [DuplicateGroup] = []
    @Published var screenState: ScreenState = .loading
    
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
            
            updateDuplicateCount()
        }
    }
    
    func setDeselectToItems(_ items: [ContactDuplicateItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.duplicates.indices {
                for item in items {
                    if let itemIndex = self.duplicates[index].contacts.firstIndex(where: { $0.id == item.id }) {
                        self.duplicates[index].contacts[itemIndex].isSelect = false
                    }
                }
            }
            
            updateDuplicateCount()
        }
    }
    
    func setSelectToAllItems() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.duplicates.indices {
                for itemIndex in self.duplicates[index].contacts.indices {
                    self.duplicates[index].contacts[itemIndex].isSelect = true
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

            if self.duplicates.isEmpty {
                self.screenState = .allClean
            }
        }
    }

    // MARK: - Private Methods
    
    private func updateDuplicateCount() {
        let totalItems = duplicates.reduce(0) { $0 + $1.contacts.count }
        duplicateCount = "\(totalItems) Duplicate"
        
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
        contactManager.getDuplicateContactGroups { duplicateGroups, isSearching in
            if !isSearching {
                DispatchQueue.main.async { [weak self] in
                    if let duplicate = duplicateGroups, !duplicate.isEmpty {
                        self?.duplicates = duplicate
                        self?.updateDuplicateCount()
                        self?.screenState = .content
                    } else {
                        self?.screenState = .allClean
                    }
                }
            } else {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.getDuplicateContactGroups()
                }
            }
        }
    }
}

