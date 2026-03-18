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
    func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation
    
    func addNovelInterest(id: NovelID) async throws(RepositoryError)
    func removeNovelInterest(id: NovelID) async throws(RepositoryError)
    
    func searchNovelByText(_ text: String) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    func searchNovelByFilter(_ filter: SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int)
    
    /// 현재 로그인한 사용자의 서재 작품 목록을 조회한다.
    ///
    /// 내부적으로 저장된 userID를 기반으로
    /// 필터 조건을 적용하여 서재 작품을 페이지네이션 형태로 반환한다.
    func fetchMyLibraryNovels(_ filter: MyLibraryFilter) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int)
    func fetchUserLibraryNovels(id: UserID) async throws(RepositoryError) -> (Paginated<LibraryNovel>, Int)
    
    func fetchRegisteredNovelStats() async throws(RepositoryError) -> RegisteredNovelStats
}
