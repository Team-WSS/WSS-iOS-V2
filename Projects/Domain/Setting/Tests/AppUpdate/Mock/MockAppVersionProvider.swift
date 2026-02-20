//
//  MockAppVersionProvider.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
@testable import SettingDomain

struct MockAppVersionProvider: AppVersionProviding {
    let currentVersion: AppVersion
}
