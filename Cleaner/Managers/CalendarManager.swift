//
//  CalendarManager.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import Foundation
import EventKit

/// Структура для хранения информации об одном событии.
struct CalendarEventItem: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    var isSelected: Bool
    let endDate: Date
    let event: EKEvent
}

/// Структура для хранения группы событий в конкретном месяце (например, October 2024).
struct EventsGroup: Identifiable {
    let id = UUID()
    let monthTitle: String
    var events: [CalendarEventItem]
    var isSelected: Bool
}

class CalendarManager {
    static let shared = CalendarManager() // Singleton
    
    private let eventStore = EKEventStore()
    var eventsGroups: [EventsGroup] = []
    private var isSearchingEvents = false
    
    private init() {}

    func checkAuthorizationStatus() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .authorized
    }

    // Запрос разрешения на доступ к календарю
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard let self = self else { return }
            if granted, error == nil {
                DispatchQueue.main.async {
                    completion(true)
                }
                UserDefaultsService.isGetCalendarAccess = true
                self.searchEventsInBackground()
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // Фоновый поиск событий и группировка
    func searchEventsInBackground() {
        guard !isSearchingEvents else { return }
        isSearchingEvents = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let now = Date()
            
            // Будем искать события за последние 20 лет с шагом в 4 года
            let intervalYears = 4
            let totalYears = 20
            
            var allEvents: [EKEvent] = []
            
            for i in stride(from: 0, to: totalYears, by: intervalYears) {
                let startDate = calendar.date(byAdding: .year, value: -(i + intervalYears), to: now)!
                let endDate = calendar.date(byAdding: .year, value: -i, to: now)!
                
                let predicate = self.eventStore.predicateForEvents(
                    withStart: startDate,
                    end: endDate,
                    calendars: nil
                )
                
                let events = self.eventStore.events(matching: predicate)
                allEvents.append(contentsOf: events)
            }
            
            // Группируем события по месяцу
            var groupedEvents = self.groupEventsByMonth(events: allEvents)
            
            // --- 1. Сортируем группы по убыванию времени (от нынешних к прошлым) ---
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            
            groupedEvents.sort { group1, group2 in
                guard let date1 = dateFormatter.date(from: group1.monthTitle),
                      let date2 = dateFormatter.date(from: group2.monthTitle) else {
                    return false
                }
                return date1 > date2
            }
            
            // --- 2. Сортируем события внутри каждой группы ---
            for i in 0..<groupedEvents.count {
                groupedEvents[i].events.sort { $0.startDate > $1.startDate }
            }
            
            // Сохраняем результат
            self.eventsGroups = groupedEvents
            self.isSearchingEvents = false
        }
    }

    // Группируем события по месяцу и году (например, October 2024)
    private func groupEventsByMonth(events: [EKEvent]) -> [EventsGroup] {
        var dictionary: [String: [EKEvent]] = [:]
        
        // Настраиваем форматер для заголовка месяцев вида "October 2024"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"

        for event in events {
            let monthTitle = dateFormatter.string(from: event.startDate)
            dictionary[monthTitle, default: []].append(event)
        }
        
        // Преобразуем в массив `EventsGroup`
        // Можно отсортировать по ключам (месяцам) для вывода в хронологическом порядке
        let sortedKeys = dictionary.keys.sorted { key1, key2 in
            // Преобразуем заголовок вида "October 2024" обратно в дату
            // чтобы правильно сравнить в хронологическом порядке
            guard let date1 = dateFormatter.date(from: key1),
                  let date2 = dateFormatter.date(from: key2) else {
                return key1 < key2
            }
            return date1 < date2
        }
        
        // Формируем массив EventsGroup
        var result: [EventsGroup] = []
        for key in sortedKeys {
            let ekEvents = dictionary[key] ?? []
            let items = ekEvents.map { ekEvent -> CalendarEventItem in
                CalendarEventItem(
                    title: ekEvent.title,
                    startDate: ekEvent.startDate,
                    isSelected: true,
                    endDate: ekEvent.endDate,
                    event: ekEvent
                )
            }
            result.append(EventsGroup(monthTitle: key, events: items, isSelected: true))
        }
        
        return result
    }
    
    // Публичный метод для получения группированных событий
    func getEventsGroups(completion: @escaping ([EventsGroup]?, Bool) -> Void) {
        if isSearchingEvents {
            // Сканирование еще идет
            completion(nil, true)
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.getEventsGroups(completion: completion)
            }
        } else {
            // Сканирование завершено, возвращаем результат
            completion(eventsGroups, false)
        }
    }
    
    // Пример удаления события (аналогично удалению контакта)
    // EKEvent сам по себе изменяемый, поэтому удалять события через:
    func deleteEvent(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            print("Event deleted: \(event.title ?? "")")
        } catch {
            print("Failed to delete event: \(error.localizedDescription)")
        }
    }
}
