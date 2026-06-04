//
//  AccountInfoRequest.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct AccountInfoRequest: Encodable {
    let gender: String
    let birth: Int
}
