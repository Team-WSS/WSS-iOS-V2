//
//  AppVersionProviding.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol AppVersionProviding {
    var currentVersion: AppVersion { get }
}