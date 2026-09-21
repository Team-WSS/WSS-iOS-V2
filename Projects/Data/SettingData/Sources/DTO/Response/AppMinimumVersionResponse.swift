//
//  AppMinimumVersionResponse.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//



import Foundation

struct AppMinimumVersionResponse: Decodable {
    var minimumVersion: String
    var updateDate: String
}
