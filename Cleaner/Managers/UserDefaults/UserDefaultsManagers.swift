//
//  UserDefaultsService.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import Foundation

enum UserDefaultsService {
    /// Is user had subscribe
    @UserDefault(.isHaveSubscribe, defaultValue: false)
    static var isHaveSubscribe: Bool

    /// is user passed onboarding
    @UserDefault(.isPassOnboarding, defaultValue: false)
    static var isPassOnboarding: Bool

    static func setValues(values: [UserDefault<Any>.Key: Any?]) {
        let keys = Array(values.keys)
        let values = Array(values.values)
        for i in 0..<values.count {
            UserDefaults.standard.set(values[i], forKey: keys[i].rawValue)
        }
    }

    private static let excludedKeys: [UserDefault<Any>.Key] = [
        .isHaveSubscribe,
        .isPassOnboarding,
    ]

    static func removeAll() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            guard !key.starts(with: "permission.") else { return }
            if !excludedKeys
                    .map({ $0.rawValue })
                    .contains(key) {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
