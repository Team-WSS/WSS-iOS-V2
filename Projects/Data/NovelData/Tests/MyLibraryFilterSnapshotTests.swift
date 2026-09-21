//
//  MyLibraryFilterSnapshotTests.swift
//  NovelData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation

@testable import NovelData
import NovelDomain
import BaseDomain

@Suite
struct MyLibraryFilterSnapshotTests {

    // MARK: - JSON 왕복(인코딩→디코딩)이 필터를 그대로 보존한다
    //
    // 영속화의 핵심 계약: 저장한 필터·정렬이 앱을 껐다 켜도 동일하게 복원돼야 한다.
    // rawValue 없는 enum(장르·매력포인트·정렬)을 안정 토큰으로 옮기므로, 라운드트립이 깨지면
    // 사용자의 마지막 필터가 조용히 유실된다.

    @Test("모든 필드를 채운 필터가 JSON 왕복 후에도 동일하게 복원된다")
    func fullFilterRoundTripsThroughJSON() throws {
        let original = MyLibraryFilter(
            isInterest: true,
            readingStatus: [.watching, .quit],
            genres: [.romance, .BL, .mystery],
            publicationStatus: .completed,
            rating: .range(min: 2.0, max: 4.5),
            attractivePoint: [.character, .writingSkill],
            keywords: [Keyword(id: KeywordID(7), name: "빙의"),
                       Keyword(id: KeywordID(9), name: "후회")],
            sortType: .ratingHighest
        )

        let restored = try roundTrip(original)

        #expect(restored == original)
    }

    @Test("별점 미설정(nil)이 왕복 후에도 nil로 남는다")
    func nilRatingRoundTrips() throws {
        let original = MyLibraryFilter(rating: nil, sortType: .registeredOldest)

        #expect(try roundTrip(original) == original)
    }

    @Test("별점 없음(unratedOnly) 모드가 범위와 구분되어 왕복된다")
    func unratedOnlyRatingRoundTrips() throws {
        let original = MyLibraryFilter(rating: .unratedOnly)

        let restored = try roundTrip(original)

        #expect(restored == original)
        #expect(restored.rating == .unratedOnly)
    }

    @Test("기본 필터(빈 상태)도 그대로 왕복된다")
    func defaultFilterRoundTrips() throws {
        let original = MyLibraryFilter()

        #expect(try roundTrip(original) == original)
    }

    // MARK: - 복원은 관대하다(알 수 없는 토큰은 건너뛴다)

    @Test("알 수 없는 토큰은 조용히 무시하고, 정렬 토큰을 못 읽으면 기본값으로 떨어진다")
    func unknownTokensAreDroppedOnDecode() {
        let snapshot = MyLibraryFilterSnapshot(
            isInterest: false,
            readingStatus: ["watching", "bogus"],   // 두 번째는 사라진 케이스 흉내
            genres: ["romance", "???"],
            publicationStatus: "completed",
            rating: nil,
            attractivePoint: [],
            keywords: [],
            sortType: "nonsense"                     // 못 읽는 정렬 → 기본값
        )

        let filter = MyLibraryFilterSnapshotMapper.filter(from: snapshot)

        #expect(filter.readingStatus == [.watching])
        #expect(filter.genres == [.romance])
        #expect(filter.sortType == .registeredNewest)
    }
}

private extension MyLibraryFilterSnapshotTests {
    /// 필터 → 스냅샷 → JSON Data → 스냅샷 → 필터. 실제 저장 경로(`DefaultMyLibraryFilterRepository`)와
    /// 같은 인코더/디코더를 태워 Codable 문제까지 함께 잡는다.
    func roundTrip(_ filter: MyLibraryFilter) throws -> MyLibraryFilter {
        let snapshot = MyLibraryFilterSnapshotMapper.snapshot(from: filter)
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MyLibraryFilterSnapshot.self, from: data)
        return MyLibraryFilterSnapshotMapper.filter(from: decoded)
    }
}
