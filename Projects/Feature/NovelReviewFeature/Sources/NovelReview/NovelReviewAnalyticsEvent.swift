//
//  NovelReviewAnalyticsEvent.swift
//  NovelReviewFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import Analytics

/// 작품 평가 화면 이벤트 이름 카탈로그(#249). 완료(`rate`/`rate_novel`) 둘을 제외한 나머지는 전부
/// V1 백로그(실제 배포된 적 없음) — 읽기상태·별점·기간·매력포인트 선택 세부 이벤트.
enum NovelReviewAnalyticsEvent: String, AnalyticsEvent {
    /// 평가 뷰 진입
    case screenViewed = "rate"
    /// 평가 완료(저장 성공)
    case saved = "rate_novel"
    /// 읽기 상태 — 보는 중
    case statusWatching = "rate_ing"
    /// 읽기 상태 — 봤어요
    case statusWatched = "rate_ed"
    /// 읽기 상태 — 하차
    case statusQuit = "rate_stop"
    /// 별점 클릭
    case ratingChanged = "rate_rating"
    /// 날짜(독서 기간) 추가 완료
    case periodConfirmed = "rate_date"
    /// 매력포인트 — 세계관
    case attractiveWorldview = "rate_universe"
    /// 매력포인트 — 소재
    case attractiveMaterial = "rate_topic"
    /// 매력포인트 — 캐릭터
    case attractiveCharacter = "rate_character"
    /// 매력포인트 — 관계
    case attractiveRelationship = "rate_relation"
    /// 매력포인트 — 분위기
    case attractiveVibe = "rate_mood"
    // ⚠️ 아래 5개(rate_keyword_*)는 이 모듈 안에서 실제로 발화되지 않는다 — 키워드 시트는
    // `KeywordFeature`(App이 조립)가 콘텐츠를 소유해 카테고리 선택을 이 enum이 못 본다.
    // 실제 트래킹은 App의 `NovelReviewAssembly.keywordSearchSheet`가 같은 문자열을 직접 들고 한다
    // (arch-lint `feature-exclusivity`가 이 enum을 App에 노출 못 하게 막아서 — 위 파일 주석 참고).
    // 여기 값은 카탈로그 문서화 목적으로만 남긴다 — **rawValue를 바꾸면 그쪽 문자열도 같이 바꿔야 한다.**
    /// 평가 키워드 — 세계관
    case keywordWorldview = "rate_keyword_universe"
    /// 평가 키워드 — 소재
    case keywordMaterial = "rate_keyword_topic"
    /// 평가 키워드 — 캐릭터
    case keywordCharacter = "rate_keyword_character"
    /// 평가 키워드 — 관계
    case keywordRelationship = "rate_keyword_relation"
    /// 평가 키워드 — 분위기
    case keywordVibe = "rate_keyword_mood"

    init(status: ReadingStatus) {
        switch status {
        case .watching: self = .statusWatching
        case .watched:  self = .statusWatched
        case .quit:     self = .statusQuit
        }
    }

    /// `AttractivePoint.writingSkill`(필력)은 CSV 이벤트 리스트에 대응 항목이 없어 nil.
    init?(attractivePoint: AttractivePoint) {
        switch attractivePoint {
        case .worldview:    self = .attractiveWorldview
        case .material:     self = .attractiveMaterial
        case .character:    self = .attractiveCharacter
        case .relationship: self = .attractiveRelationship
        case .vibe:         self = .attractiveVibe
        case .writingSkill: return nil
        }
    }
}
