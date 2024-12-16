//
//  UserDefaultsPropertyWrapper.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.12.2024.
//

import Foundation

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool {
        self == nil
    }
    
    var isNotNil: Bool {
        self != nil
    }
}

@propertyWrapper
struct UserDefault<T> {
    let key: Key
    let defaultValue: T

    init(_ key: Key, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                UserDefaults.standard.removeObject(forKey: key.rawValue)
            } else {
                UserDefaults.standard.set(newValue, forKey: key.rawValue)
            }
        }
    }
}

extension UserDefault {
    enum Key: String {
        case isHaveSubscribe = "isHaveSubscribe"
        case isPassOnboarding = "IsPassOnboarding"
    }
}
