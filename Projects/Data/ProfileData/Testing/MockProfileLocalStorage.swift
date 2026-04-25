//
//  MockProfileLocalStorage.swift
//  ProfileDataTesting
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

@testable import ProfileData

public final class MockProfileLocalStorage: ProfileLocalStorage {
    public var userID: Int?
    public var nickname: String?
    public var characterID: Int?
    public var gender: String?

    public init() {}
}
