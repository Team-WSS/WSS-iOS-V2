//
//  LoadMyLibraryKeywordsUseCase.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 내가 서재 작품들에 등록한 키워드 목록을 불러온다. (필터 시트 키워드 탭)
public protocol LoadMyLibraryKeywordsUseCase: Sendable {
    func execute() async throws(RepositoryError) -> [Keyword]
}

public final class DefaultLoadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase {

    private let novelRepository: NovelRepository

    public init(novelRepository: NovelRepository) {
        self.novelRepository = novelRepository
    }

    public func execute() async throws(RepositoryError) -> [Keyword] {
        try await novelRepository.fetchMyLibraryKeywords()
    }
}
