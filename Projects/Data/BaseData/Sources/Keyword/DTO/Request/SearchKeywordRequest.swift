//
//  SearchKeywordRequest.swift
//  BaseData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct SearchKeywordRequest: QueryItemConvertible {
    let query: String
}
