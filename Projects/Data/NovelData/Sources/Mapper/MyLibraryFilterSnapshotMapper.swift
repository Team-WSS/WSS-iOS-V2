//
//  MyLibraryFilterSnapshotMapper.swift
//  NovelData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain
import BaseDomain

/// 내 서재 필터·정렬의 **로컬 영속 스냅샷**(JSON 직렬화 포맷, #221).
///
/// 도메인 값(`MyLibraryFilter`)을 그대로 `Codable`로 만들지 않고 이 DTO를 거치는 이유:
/// ① 영속 포맷을 **서버 토큰과 분리**한다 — 서버가 받는 정렬/장르 문자열(`created_desc`·영문 장르 등)이
///    바뀌어도 저장된 값이 안 깨진다(반대로 이 토큰을 서버 매퍼와 공유하면 서버 스펙 변경이 사용자
///    로컬 저장을 조용히 깬다). ② `NovelGenre`·`AttractivePoint`·`LibrarySortType`은 rawValue가 없어
///    안정 토큰을 코덱이 명시해야 한다.
struct MyLibraryFilterSnapshot: Codable {
    var isInterest: Bool
    var readingStatus: [String]
    var genres: [String]
    var publicationStatus: String?
    var rating: Rating?
    var attractivePoint: [String]
    var keywords: [KeywordSnapshot]
    var sortType: String

    struct Rating: Codable {
        var unratedOnly: Bool
        var min: Float?
        var max: Float?
    }

    struct KeywordSnapshot: Codable {
        var id: Int
        var name: String
    }
}

/// `MyLibraryFilter` ↔ `MyLibraryFilterSnapshot` 변환.
///
/// **복원은 관대하다(best-effort)**: 알 수 없는 토큰(앱 업데이트로 enum 케이스가 사라졌거나 저장 포맷이
/// 바뀐 경우)은 조용히 건너뛰고, 정렬 토큰을 못 읽으면 기본값(`.registeredNewest`)으로 떨어진다.
/// 저장 방향은 `switch`가 강제하므로 enum에 케이스를 추가하면 여기서 컴파일 에러로 잡힌다(토큰 누락 방지).
enum MyLibraryFilterSnapshotMapper {

    // MARK: - MyLibraryFilter → Snapshot

    static func snapshot(from filter: MyLibraryFilter) -> MyLibraryFilterSnapshot {
        MyLibraryFilterSnapshot(
            isInterest: filter.isInterest,
            readingStatus: filter.readingStatus.map(\.rawValue),
            genres: filter.genres.map(genreToken(_:)),
            publicationStatus: filter.publicationStatus?.rawValue,
            rating: ratingSnapshot(from: filter.rating),
            attractivePoint: filter.attractivePoint.map(attractivePointToken(_:)),
            keywords: filter.keywords.map { .init(id: $0.id.value, name: $0.name) },
            sortType: sortToken(filter.sortType)
        )
    }

    // MARK: - Snapshot → MyLibraryFilter

    static func filter(from snapshot: MyLibraryFilterSnapshot) -> MyLibraryFilter {
        MyLibraryFilter(
            isInterest: snapshot.isInterest,
            readingStatus: snapshot.readingStatus.compactMap(ReadingStatus.init(rawValue:)),
            genres: snapshot.genres.compactMap(genre(fromToken:)),
            publicationStatus: snapshot.publicationStatus.flatMap(NovelPublicationStatus.init(rawValue:)),
            rating: rating(from: snapshot.rating),
            attractivePoint: snapshot.attractivePoint.compactMap(attractivePoint(fromToken:)),
            keywords: snapshot.keywords.map { Keyword(id: KeywordID($0.id), name: $0.name) },
            sortType: sort(fromToken: snapshot.sortType) ?? .registeredNewest
        )
    }
}

// MARK: - 별점

private extension MyLibraryFilterSnapshotMapper {

    static func ratingSnapshot(from rating: LibraryRatingFilter?) -> MyLibraryFilterSnapshot.Rating? {
        switch rating {
        case .none:
            return nil
        case .unratedOnly:
            return .init(unratedOnly: true, min: nil, max: nil)
        case let .range(min, max):
            return .init(unratedOnly: false, min: min, max: max)
        }
    }

    static func rating(from snapshot: MyLibraryFilterSnapshot.Rating?) -> LibraryRatingFilter? {
        guard let snapshot else { return nil }
        if snapshot.unratedOnly { return .unratedOnly }
        guard let min = snapshot.min, let max = snapshot.max else { return nil }
        return .range(min: min, max: max)
    }
}

// MARK: - 안정 토큰 (rawValue 없는 enum — 서버 문자열과 분리)

private extension MyLibraryFilterSnapshotMapper {

    static func genreToken(_ genre: NovelGenre) -> String {
        switch genre {
        case .lightNovel:     "lightNovel"
        case .wuxia:          "wuxia"
        case .fantasy:        "fantasy"
        case .romance:        "romance"
        case .BL:             "BL"
        case .romanceFantasy: "romanceFantasy"
        case .modernFantasy:  "modernFantasy"
        case .drama:          "drama"
        case .mystery:        "mystery"
        }
    }

    static func genre(fromToken token: String) -> NovelGenre? {
        switch token {
        case "lightNovel":     .lightNovel
        case "wuxia":          .wuxia
        case "fantasy":        .fantasy
        case "romance":        .romance
        case "BL":             .BL
        case "romanceFantasy": .romanceFantasy
        case "modernFantasy":  .modernFantasy
        case "drama":          .drama
        case "mystery":        .mystery
        default:               nil
        }
    }

    static func attractivePointToken(_ point: AttractivePoint) -> String {
        switch point {
        case .worldview:    "worldview"
        case .material:     "material"
        case .character:    "character"
        case .relationship: "relationship"
        case .vibe:         "vibe"
        case .writingSkill: "writingSkill"
        }
    }

    static func attractivePoint(fromToken token: String) -> AttractivePoint? {
        switch token {
        case "worldview":    .worldview
        case "material":     .material
        case "character":    .character
        case "relationship": .relationship
        case "vibe":         .vibe
        case "writingSkill": .writingSkill
        default:             nil
        }
    }

    static func sortToken(_ sortType: LibrarySortType) -> String {
        switch sortType {
        case .registeredNewest: "registeredNewest"
        case .registeredOldest: "registeredOldest"
        case .title:            "title"
        case .readDate:         "readDate"
        case .ratingHighest:    "ratingHighest"
        case .ratingLowest:     "ratingLowest"
        }
    }

    static func sort(fromToken token: String) -> LibrarySortType? {
        switch token {
        case "registeredNewest": .registeredNewest
        case "registeredOldest": .registeredOldest
        case "title":            .title
        case "readDate":         .readDate
        case "ratingHighest":    .ratingHighest
        case "ratingLowest":     .ratingLowest
        default:                 nil
        }
    }
}
