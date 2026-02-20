//
//  AppUpdatePolicy.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public struct AppUpdatePolicy: Equatable {
    public let minimumVersion: AppVersion
    public let updateDate: Date?

    public init(minimumVersion: AppVersion, updateDate: Date?) {
        self.minimumVersion = minimumVersion
        self.updateDate = updateDate
    }

    /// 현재 버전이 minimumVersion보다 낮으면 강제 업데이트 필요
    public func requiresForceUpdate(current: AppVersion) -> Bool {
        current < minimumVersion
    }
}