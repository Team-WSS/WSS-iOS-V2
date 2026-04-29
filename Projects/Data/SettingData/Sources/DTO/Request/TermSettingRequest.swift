//
//  TermSettingRequest.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//



import Foundation
import Networking

struct TermSettingRequest: RequestBodyConvertible {
    let serviceAgreed: Bool
    let privacyAgreed: Bool
    let marketingAgreed: Bool
}
