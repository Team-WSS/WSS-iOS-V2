//
//  NovelPlatformResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NovelPlatformResponse: Decodable {
    public let platformName: String
    public let platformImage: String
    public let platformUrl: String
}
