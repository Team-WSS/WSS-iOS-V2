//
//  TermSettingRequest.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//



import Foundation

struct TermSettingRequest: Encodable {
    let serviceAgreed: Bool
    let privacyAgreed: Bool
    let marketingAgreed: Bool
}
