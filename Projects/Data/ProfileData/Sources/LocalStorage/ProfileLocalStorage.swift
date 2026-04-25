//
//  ProfileLocalStorage.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol ProfileLocalStorage {
    var userID: Int? { get set }
    var nickname: String? { get set }
    var characterID: Int? { get set }
    var gender: String? { get set }
}

public struct ProfileUserDefaultsStorage: ProfileLocalStorage {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var userID: Int? {
        get {
            let value = defaults.integer(forKey: Key.userID)
            return value == 0 ? nil : value
        }
        set { defaults.set(newValue, forKey: Key.userID) }
    }

    public var nickname: String? {
        get { defaults.string(forKey: Key.nickname) }
        set { defaults.set(newValue, forKey: Key.nickname) }
    }

    public var characterID: Int? {
        get {
            let value = defaults.integer(forKey: Key.characterID)
            return value == 0 ? nil : value
        }
        set { defaults.set(newValue, forKey: Key.characterID) }
    }

    public var gender: String? {
        get { defaults.string(forKey: Key.gender) }
        set { defaults.set(newValue, forKey: Key.gender) }
    }
}

// TODO: 혹시 해당 정보들 다른데서 쓰일 곳 있을지? profile 이라고 키 값 명시해도 될지 싶어서
private enum Key {
    static let userID = "profile.userID"
    static let nickname = "profile.nickname"
    static let characterID = "profile.characterID"
    static let gender = "profile.gender"
}
