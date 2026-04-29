//
//  ConversionType.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


enum ConversionType: CustomStringConvertible {
    case appVersion
    case updateDate

    var description: String {
        switch self {
        case .appVersion:
            return "AppVersion"
        case .updateDate:
            return "UpdateDate"
        }
    }
}
