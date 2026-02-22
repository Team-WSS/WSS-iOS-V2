//
//  MockAppVersionProvider.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SettingDomain

public struct MockAppVersionProvider: AppVersionProviding {
    public let currentVersion: AppVersion

    public init(currentVersion: AppVersion) {
        self.currentVersion = currentVersion
    }
}
