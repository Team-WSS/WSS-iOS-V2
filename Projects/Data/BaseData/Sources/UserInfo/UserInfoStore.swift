//
//  UserInfoStore.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum UserInfoStore {

    private enum Key {
        static let userID = "myID"
        static let nickname = "myNickname"
        static let gender = "myGender"
    }

    // MARK: - UserID

    public static var userID: Int {
        get { UserDefaults.standard.integer(forKey: Key.userID) }
        set { UserDefaults.standard.set(newValue, forKey: Key.userID) }
    }

    // MARK: - Nickname

    public static var nickname: String? {
        get { UserDefaults.standard.string(forKey: Key.nickname) }
        set { UserDefaults.standard.set(newValue, forKey: Key.nickname) }
    }

    // MARK: - Gender

    public static var gender: String? {
        get { UserDefaults.standard.string(forKey: Key.gender) }
        set { UserDefaults.standard.set(newValue, forKey: Key.gender) }
    }
}
