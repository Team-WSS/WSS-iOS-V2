//
//  MockUserDataStore.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import AuthDomain


final class MockUserDataStore: UserDataStore {
    private(set) var clearUserDataCallCount: Int = 0

    func clearUserData() {
        clearUserDataCallCount += 1
    }
}
