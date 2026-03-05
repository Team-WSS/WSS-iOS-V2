//
//  NovelInterestUseCase.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol NovelInterestUseCase {
    func add(id: NovelID) async throws
    func remove(id: NovelID) async throws
}

public final class DefaultNovelInterestUseCase: NovelInterestUseCase {
    
    private let novelRepository: NovelRepository
    
    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }
    
    public func add(id: NovelID) async throws {
        try await novelRepository.addNovelInterest(id: id)
    }
    
    public func remove(id: NovelID) async throws {
        try await novelRepository.removeNovelInterest(id: id)
    }
}
