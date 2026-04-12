//
//  NormalSearchQuery.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct NormalSearchQuery: QueryItemConvertible {
    let query: String
    let page: Int
    let size: Int
}
