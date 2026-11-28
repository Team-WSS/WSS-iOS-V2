//
//  MockLoadTotalKeywordsUseCase.swift
//  BaseDomain
//
//  Created by YunhakLee on 11/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 전체 키워드 불러오기 가짜 객체.
/// 조회라 정해 둔 값(`result`)만 돌려주고 호출을 기록하지 않는다(Stub).
/// 이 UseCase를 받아 쓰는 다른 모듈 테스트가, 키워드 저장소의 동기화·재조회 같은 속사정을 몰라도 되게 둔다.
public final class MockLoadTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    public var result: Result<[KeywordGroup], RepositoryError>

    public init(result: Result<[KeywordGroup], RepositoryError> = .success([])) {
        self.result = result
    }

    public func execute() async throws(RepositoryError) -> [KeywordGroup] {
        try result.get()
    }
}
