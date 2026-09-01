//
//  MyLibraryFilterUseCaseTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct MyLibraryFilterUseCaseTests {

    // MARK: - Load

    @Test("저장된 필터가 있으면 그대로 복원한다")
    func loadReturnsStoredFilter() {
        let stored = MyLibraryFilter(genres: [.romance], sortType: .ratingHighest)
        let mock = MockMyLibraryFilterRepository(storedFilter: stored)
        let usecase = DefaultLoadMyLibraryFilterUseCase(repository: mock)

        let result = usecase.execute()

        #expect(result == stored)
        #expect(mock.loadCallCount == 1)
    }

    @Test("저장된 필터가 없으면 nil을 반환한다(화면은 기본 필터로 시작)")
    func loadReturnsNilWhenEmpty() {
        let mock = MockMyLibraryFilterRepository(storedFilter: nil)
        let usecase = DefaultLoadMyLibraryFilterUseCase(repository: mock)

        #expect(usecase.execute() == nil)
    }

    // MARK: - Save

    @Test("저장하면 넘긴 필터를 Repository에 그대로 위임한다")
    func saveDelegatesFilter() {
        let mock = MockMyLibraryFilterRepository()
        let usecase = DefaultSaveMyLibraryFilterUseCase(repository: mock)
        let filter = MyLibraryFilter(isInterest: true, sortType: .title)

        usecase.execute(filter)

        #expect(mock.savedFilters == [filter])
    }
}
