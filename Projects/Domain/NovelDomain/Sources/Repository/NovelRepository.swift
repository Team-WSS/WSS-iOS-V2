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
    /// 특정 작품의 전체 정보를 조회한다.
    ///
    /// - 작품의 헤더 정보(Novel)
    /// - 작품의 상세 정보(NovelInformation)
    ///
    /// 위 두 정보를 한 번의 요청으로 함께 반환한다.
    /// 키워드 매핑을 위해 캐시된 키워드 목록을 전달받는다.
    func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation
    
    func addNovelInterest(id: NovelID) async throws(RepositoryError)
    func removeNovelInterest(id: NovelID) async throws(RepositoryError)

    /// 현재 로그인한 사용자의 서재 작품 목록을 조회한다. (V2 — 커서 기반)
    ///
    /// 내부적으로 저장된 userID를 기반으로 필터·정렬을 적용해 조회한다.
    /// - Parameters:
    ///   - cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    ///   - cachedKeywords: 응답의 키워드 이름을 `Keyword`로 복원할 때 사용할 전체 키워드 캐시.
    /// - Returns: (커서 페이지, 필터 적용된 전체 작품 수)
    func fetchMyLibraryNovels(
        _ filter: MyLibraryFilter,
        cursor: String?,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int)

    /// 다른 사용자의 서재 작품 목록을 조회한다. (V2 — 커서 기반)
    ///
    /// 내 서재와 **같은 엔드포인트**(`/users/{userId}/novels/v2`)를 userID만 바꿔 호출한다 →
    /// 커서 페이지네이션·정렬 6종·키워드 복원이 내 서재와 동일하게 동작한다.
    /// - Parameters:
    ///   - id: 조회 대상 사용자.
    ///   - cursor: 직전 응답의 `nextCursor`. 첫 페이지는 nil.
    ///   - cachedKeywords: 응답의 키워드 이름을 `Keyword`로 복원할 때 사용할 전체 키워드 캐시.
    /// - Returns: (커서 페이지, 전체 작품 수)
    func fetchUserLibraryNovels(
        id: UserID,
        _ filter: LibraryFilter,
        cursor: String?,
        cachedKeywords: [Keyword]
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int)

    /// 현재 로그인한 사용자가 서재 작품들에 등록한 키워드 목록을 조회한다. (필터 시트 키워드 탭 데이터)
    func fetchMyLibraryKeywords() async throws(RepositoryError) -> [Keyword]
    
    func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats
    func fetchUserRegisteredNovelStats(id: UserID) async throws(RepositoryError) -> RegisteredNovelStats
}
