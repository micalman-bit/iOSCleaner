//
//  CalendarManager.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import Foundation
import Contacts

struct ContactDuplicateItem: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    var isSelect: Bool
    let item: CNContact
}

struct ContactDuplicateGroup: Identifiable {
    let id = UUID()
    var contacts: [ContactDuplicateItem]
}

class ContactManager {
    static let shared = ContactManager() // Singleton

    private let contactStore = CNContactStore()
    private var duplicateGroups: [ContactDuplicateGroup] = []
    private var isSearchingDuplicates = false
    
    private init() {}
    
    func requestContactsAccess(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            if granted, error == nil {
                DispatchQueue.main.async {
                    completion(true)
                }
                self.searchDuplicateContactsInBackground()
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func searchDuplicateContactsInBackground() {
        guard !isSearchingDuplicates else { return }
        isSearchingDuplicates = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ])
            
            var contacts: [CNContact] = []
            do {
                try self.contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                    contacts.append(contact)
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
                self.isSearchingDuplicates = false
                return
            }
            
            let duplicateGroups = self.findDuplicateGroups(in: contacts)
            self.duplicateGroups = duplicateGroups
            self.isSearchingDuplicates = false
        }
    }
    
    private func findDuplicateGroups(in contacts: [CNContact]) -> [ContactDuplicateGroup] {
        var phoneNumberToContacts: [String: [CNContact]] = [:]

        for contact in contacts {
            let normalizedPhoneNumbers = contact.phoneNumbers.map { phoneNumber -> String in
                let rawValue = phoneNumber.value.stringValue
                return rawValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            }

            for phoneNumber in normalizedPhoneNumbers {
                if phoneNumberToContacts[phoneNumber] != nil {
                    phoneNumberToContacts[phoneNumber]?.append(contact)
                } else {
                    phoneNumberToContacts[phoneNumber] = [contact]
                }
            }
        }

        let filteredGroups = phoneNumberToContacts.values
            .filter { $0.count > 1 }
            .map { group in
                group.map { contact in
                    let name = contact.givenName.isEmpty ? "Unknown" : contact.givenName
                    let number = contact.phoneNumbers.first?.value.stringValue ?? "No Number"
                    return ContactDuplicateItem(name: name, number: number, isSelect: true, item: contact)
                }
            }
        
        return filteredGroups.map { ContactDuplicateGroup(contacts: $0) }
    }
    
    func getDuplicateContactGroups(completion: @escaping ([ContactDuplicateGroup]?, Bool) -> Void) {
        if isSearchingDuplicates {
            completion(nil, true)
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.getDuplicateContactGroups(completion: completion)
            }
        } else {
            completion(duplicateGroups, false)
        }
    }
    
    func deleteContact(_ contact: CNContact) {
        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }
        
        let request = CNSaveRequest()
        request.delete(mutableContact)
        
        do {
            try contactStore.execute(request)
            print("Contact deleted: \(mutableContact.givenName) \(mutableContact.familyName)")
        } catch {
            print("Failed to delete contact: \(error.localizedDescription)")
        }
    }

}
