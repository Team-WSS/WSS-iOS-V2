//
//  UserRegisteredNovelStatesResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct UserRegisteredNovelStatesResponse: Decodable {
    public let interestNovelCount: Int
    public let watchingNovelCount: Int
    public let watchedNovelCount: Int
    public let quitNovelCount: Int
}
