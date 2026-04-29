//
//  TermSettingResponse.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

struct TermSettingResponse: Decodable {
    let serviceAgreed: Bool
    let privacyAgreed: Bool
    let marketingAgreed: Bool
}