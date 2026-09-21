//
//  DemoSessionTokenStore.swift
//  Networking
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct DemoSessionTokenStore: SessionTokenStore {
    
    public init () { }
    
    public func clearTokens() throws { }
    
    public func accessToken() throws -> String? {
        return NetworkingConfig.testApiKey
    }
}
