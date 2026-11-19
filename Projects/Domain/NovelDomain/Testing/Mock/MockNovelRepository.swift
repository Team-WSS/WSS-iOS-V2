//
//  MockNovelRepository.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain

/// 작품 저장소 가짜 객체.
/// 조회는 정해 둔 값만 돌려주고 호출을 기록하지 않는다(Stub).
/// 작품 상세·서재 조회는 **넘겨받은 키워드 캐시마다** 답을 정해 둔다 — 정해 두지 않은 캐시로 부르면 `.notFound`를 던진다.
/// 그래서 UseCase가 키워드를 잘못 넘기면 결과가 달라진다. 키워드 순서는 따지지 않는다(`Set`).
/// 나머지 조회와 관심 추가·해제(명령)는 쓰는 테스트가 없어 답을 정해 두지 않는다 — 필요해지면 그때 더한다.
public final class MockNovelRepository: NovelRepository {
    public var novelsByCachedKeywords: [Set<Keyword>: NovelInformation] = [:]
    public var myLibraryByCachedKeywords: [Set<Keyword>: (CursorPaginated<LibraryNovel>, Int)] = [:]
    public var userLibraryByCachedKeywords: [Set<Keyword>: (CursorPaginated<LibraryNovel>, Int)] = [:]

    public init() {}

    public func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation {
        guard let novel = novelsByCachedKeywords[Set(cachedKeywords)] else { throw .notFound }
        return novel
    }

    public func addNovelInterest(id: NovelID) async throws(RepositoryError) {}

    public func removeNovelInterest(id: NovelID) async throws(RepositoryError) {}

    public func fetchMyLibraryNovels(
        _ filter: MyLibraryFilter,
        cursor: String?,
        size: Int,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        guard let page = myLibraryByCachedKeywords[Set(cachedKeywords)] else { throw .notFound }
        return page
    }

    public func fetchUserLibraryNovels(
        id: UserID,
        _ filter: LibraryFilter,
        cursor: String?,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        guard let page = userLibraryByCachedKeywords[Set(cachedKeywords)] else { throw .notFound }
        return page
    }

    public func fetchMyLibraryKeywords() async throws(RepositoryError) -> [Keyword] {
        throw .notFound
    }

    public func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats {
        throw .notFound
    }

    public func fetchUserRegisteredNovelStats(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats {
        throw .notFound
    }
}
