//
//  NovelRepository.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol NovelRepository {
    func fetchNovel(id: NovelID) async throws -> (Novel, NovelInformation)
    
    func searchNovelByText(_ text: String) async throws -> Paginated<Novel>
    func searchNovelByFilter(_ filter: NovelSearchFilter) async throws -> Paginated<Novel>
    
    func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws -> Paginated<LibraryNovel>
    func fetchUserLibraryNovels(id: UserID) async throws -> Paginated<LibraryNovel>
}
