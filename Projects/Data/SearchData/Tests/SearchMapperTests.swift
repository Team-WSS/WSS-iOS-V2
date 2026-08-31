//
//  SearchMapperTests.swift
//  SearchDataTests
//

import Testing

@testable import SearchData
import SearchDomain
import BaseDomain

@Suite
struct SearchMapperTests {

    // MARK: - detailSearchQuery: 연재상태 → isCompleted 매핑
    //
    // 연재상태(publicationStatus)를 상세탐색 쿼리의 `isCompleted`(Bool?)로 옮기는 규칙을 고정한다.
    // 미선택(nil)을 false로 접으면 서버가 "연재중만"으로 해석해 완결작 ~90%가 누락되는 회귀가 있었다(#221) —
    // 미선택은 반드시 nil로 남아 파라미터가 생략돼야 한다.

    @Test("연재상태를 선택하지 않으면(nil) isCompleted가 nil이라 쿼리 파라미터에서 생략된다")
    func publicationStatusNilMapsToNilIsCompleted() {
        let filter = makeFilter(publicationStatus: nil)                    // Given

        let query = SearchMapper.detailSearchQuery(from: filter, page: 0)  // When

        #expect(query.isCompleted == nil)                                  // Then
    }

    @Test("완결작(completed)을 선택하면 isCompleted가 true다")
    func completedMapsToTrue() {
        let filter = makeFilter(publicationStatus: .completed)

        let query = SearchMapper.detailSearchQuery(from: filter, page: 0)

        #expect(query.isCompleted == true)
    }

    @Test("연재중(onGoing)을 선택하면 isCompleted가 false다")
    func onGoingMapsToFalse() {
        let filter = makeFilter(publicationStatus: .onGoing)

        let query = SearchMapper.detailSearchQuery(from: filter, page: 0)

        #expect(query.isCompleted == false)
    }
}

private extension SearchMapperTests {
    func makeFilter(publicationStatus: NovelPublicationStatus?) -> SearchFilter {
        SearchFilter(publicationStatus: publicationStatus)
    }
}
