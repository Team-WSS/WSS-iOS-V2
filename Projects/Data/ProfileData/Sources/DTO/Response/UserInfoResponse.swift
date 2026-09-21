//
//  UserBasicInfoResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct UserInfoResponse: Decodable {
    let userId: Int
    let gender: String
    let nickname: String
}
