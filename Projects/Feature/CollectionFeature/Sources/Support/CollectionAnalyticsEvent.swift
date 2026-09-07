//
//  CollectionAnalyticsEvent.swift
//  CollectionFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 이 모듈(컬렉션 목록·상세·생성/수정) 전체가 공유하는 이벤트 이름 카탈로그.
enum CollectionAnalyticsEvent: String, AnalyticsEvent {
    /// 컬렉션 목록 화면 진입
    case screenViewed = "collection_list"
    /// "컬렉션 만들기" 버튼 클릭(목록 상단·빈 상태 공용)
    case createButtonTapped = "collection_create_btn"
    /// 생성/수정 화면 진입(겸용 화면이라 모드 구분 없이 공통)
    case writeViewed = "collection_write"
    /// 생성 완료(저장 성공, 수정은 제외)
    case saved = "collection_save"
    /// 컬렉션 상세 화면 진입
    case detailViewed = "collection_detail"
    /// 컬렉션 좋아요 토글
    case likeToggled = "collection_like"
    /// 컬렉션 삭제 확정
    case deleteConfirmed = "collection_delete"
}
