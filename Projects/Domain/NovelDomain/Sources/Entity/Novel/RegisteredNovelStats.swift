//
//  RegisteredNovelStats.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct RegisteredNovelStats {
    public let interest: Int
    public let watching: Int
    public let watched: Int
    public let quit: Int
    
    public init(
        interest: Int,
        watching: Int,
        watched: Int, 
        quit: Int
    ) {
        self.interest = interest
        self.watching = watching
        self.watched = watched
        self.quit = quit
    }
}
