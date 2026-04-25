//
//  AccountInfoResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct AccountInfoResponse: Decodable {
    let email: String
    let gender: String
    let birth: Int
}
