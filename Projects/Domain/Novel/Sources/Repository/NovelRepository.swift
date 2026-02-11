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
    func fetchNovelDetail(id: NovelID) async throws -> NovelDetail
    func fetchNovelInformation(id: NovelID) async throws -> NovelInformation
    
    func searchNovelByText(_ text: String) async throws -> Paginated<Novel>
    func searchNovelByFilter(_ filter: NovelSearchFilter) async throws -> Paginated<Novel>
}
