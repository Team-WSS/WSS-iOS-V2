//
//  LibraryNovels.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct LibraryNovels {
    public let totalCount: Int
    public let novels: Paginated<LibraryNovel>
    
    public init(totalCount: Int, novels: Paginated<LibraryNovel>) {
        self.totalCount = totalCount
        self.novels = novels
    }
}
