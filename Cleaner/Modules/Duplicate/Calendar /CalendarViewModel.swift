//
//  CalendarViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import UIKit
import Photos

final class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var duplicateCount: String = ""
    @Published var groupCount: String = ""
    
    @Published var isShowDeleteAlert: Bool = false
    @Published var titleDeleteAlert: String = ""
    @Published var messageDeleteAlert: String = "Selected records will be irrevocably deleted with no possibility of recovery."
    
    @Published var isEnabledButton: Bool = false
    
    @Published var events: [EventsGroup] = []
    @Published var screenState: ScreenState = .loading
    
    // MARK: - Private Properties
    
    private let service: CalendarService
    private let router: CalendarRouter
    private let сalendarManager = CalendarManager.shared
    
    // MARK: - Init
    
    init(
        service: CalendarService,
        router: CalendarRouter
    ) {
        self.service = service
        self.router = router
        
        getDuplicateContactGroups()
    }
    
    // MARK: - Public Methods
    
    func dismiss() {
        router.dismiss()
    }
    
    func setSelectToItem(_ item: CalendarEventItem) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.events.indices {
                if let itemIndex = self.events[index].events.firstIndex(where: { $0.id == item.id }) {
                    self.events[index].events[itemIndex].isSelected.toggle()
                    break
                }
            }
            
            updateDuplicateCount()
        }
    }
    
    func setDeselectToItems(_ items: EventsGroup) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.events.indices {
                for item in items.events {
                    if let itemIndex = self.events[index].events.firstIndex(where: { $0.id == item.id }) {
                        self.events[index].events[itemIndex].isSelected = false
                    }
                }
            }
            
            updateDuplicateCount()
        }
    }
    
    func setSelectToAllItems() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for index in self.events.indices {
                for itemIndex in self.events[index].events.indices {
                    self.events[index].events[itemIndex].isSelected = true
                }
            }
            
            updateDuplicateCount()
        }
    }
    
    func mergeContacts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for groupIndex in self.events.indices {
                
                let remainingContacts = self.events[groupIndex].events
                
                let selectedEvent = remainingContacts.filter { $0.isSelected }
                
                for event in selectedEvent {
                    self.сalendarManager.deleteEvent(event.event)
                }
                
                self.events[groupIndex].events.removeAll { contact in
                    remainingContacts.contains(where: { $0.id == contact.id }) && contact.isSelected
                }
            }
            
            self.events.removeAll(where: { $0.events.count <= 0 })
            self.сalendarManager.eventsGroups = events
            
            self.updateDuplicateCount()
            
            if self.events.isEmpty {
                self.screenState = .allClean
            }
        }
    }
    
    // MARK: - Private Methods
    
    
    private func updateDuplicateCount() {
        let totalItems = events.reduce(0) { $0 + $1.events.count }
        duplicateCount = "\(totalItems) events"
        
        let selectedCount = events.reduce(0) { result, group in
            result + group.events.filter { $0.isSelected }.count
        }
        
        if selectedCount > 0 {
            titleDeleteAlert = "DELETE \(selectedCount) EVENTS?"
            groupCount = "DELETE \(selectedCount) EVENTS"
            isEnabledButton = true
        } else {
            groupCount = "DELETE EVENTS"
            isEnabledButton = false
        }
    }

    private func getDuplicateContactGroups() {
        сalendarManager.getEventsGroups { eventsGroup, isSearching in
            if !isSearching {
                DispatchQueue.main.async { [weak self] in
                    if let events = eventsGroup, !events.isEmpty {
                        self?.events = events
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

