//
//  CalendarManager.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import Foundation
import Contacts

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
    /// Кэш найденных групп дубликатов
    private var duplicateGroups: [ContactDuplicateGroup] = []
    /// Флаг, указывающий, идет ли поиск
    private var isSearchingDuplicates = false
    
    // Свойства для отслеживания прогресса поиска (0...100)
    private var duplicateSearchProgress: Double = 0.0
    private var duplicateSearchTotal: Int = 0
    private var duplicateSearchProcessed: Int = 0

    private init() {}
    
    func checkAuthorizationStatus() -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return status == .authorized
    }

    /// Запрашивает доступ к контактам и запускает поиск дубликатов
    func requestContactsAccess(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            if granted, error == nil {
                DispatchQueue.main.async {
                    completion(true)
                }
                UserDefaultsService.isGetContactsAccess = true
                self.startDuplicateSearch()
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Запускает асинхронный поиск дубликатов контактов с отслеживанием прогресса
    func startDuplicateSearch() {
        guard !isSearchingDuplicates else { return }
        isSearchingDuplicates = true
        duplicateSearchProgress = 0.0
        duplicateSearchProcessed = 0
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Получаем все контакты
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
            
            self.duplicateSearchTotal = contacts.count
            var phoneNumberToContacts: [String: [CNContact]] = [:]
            
            // Перебираем контакты и обновляем прогресс
            for contact in contacts {
                self.duplicateSearchProcessed += 1
                self.duplicateSearchProgress = (Double(self.duplicateSearchProcessed) / Double(self.duplicateSearchTotal)) * 100
                
                let normalizedPhoneNumbers = contact.phoneNumbers.map { phoneNumber -> String in
                    let rawValue = phoneNumber.value.stringValue
                    return rawValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                }
                
                for phoneNumber in normalizedPhoneNumbers {
                    phoneNumberToContacts[phoneNumber, default: []].append(contact)
                }
            }
            
            // Фильтруем группы, в которых больше одного контакта
            let filteredGroups = phoneNumberToContacts.values.filter { $0.count > 1 }
            let duplicateGroups = filteredGroups.map { group in
                group.map { contact in
                    let name = contact.givenName.isEmpty ? "Unknown" : contact.givenName
                    let number = contact.phoneNumbers.first?.value.stringValue ?? "No Number"
                    return ContactDuplicateItem(name: name, number: number, isSelect: true, item: contact)
                }
            }.map { ContactDuplicateGroup(contacts: $0) }
            
            self.duplicateGroups = duplicateGroups
            self.isSearchingDuplicates = false
            self.duplicateSearchProgress = 100
            
            // Если нужно, можно уведомить об окончании поиска (например, через NotificationCenter или callback)
            DispatchQueue.main.async {
                // Например: NotificationCenter.default.post(name: .didUpdateDuplicateContacts, object: nil)
            }
        }
    }
    
    /// Возвращает статус поиска дубликатов:
    /// - isScanning: идет ли поиск
    /// - progress: текущий прогресс (0 до 100)
    /// - duplicateGroups: найденные группы (если поиск завершен; иначе – пустой массив)
    func getDuplicateSearchStatus() -> (isScanning: Bool, progress: Double, duplicateGroups: [ContactDuplicateGroup]) {
        if isSearchingDuplicates {
            return (true, duplicateSearchProgress, [])
        } else {
            return (false, 100, duplicateGroups)
        }
    }
    
    /// Удаляет указанный контакт
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
