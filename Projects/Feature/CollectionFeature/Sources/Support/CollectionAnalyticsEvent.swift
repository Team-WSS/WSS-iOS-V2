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

    // MARK: - V2 신규(CSV에 없음)

    /// 컬렉션 목록 탭 전환(내 컬렉션/좋아요한 컬렉션)
    case tabSelected = "collection_tab_select"
    /// 컬렉션 상세 정렬 변경
    case sortChanged = "collection_sort"
    /// 컬렉션 상세 더보기 > 수정 클릭
    case editTapped = "collection_edit_btn"
    /// 생성/수정 화면 비공개 전환
    case privateOn = "collection_private_on"
    /// 생성/수정 화면 공개 전환
    case privateOff = "collection_private_off"
    /// 대표 작품 지정
    case representativeNovelSelected = "collection_representative_select"
    /// "작품 추가" 화면 진입
    case addNovelViewed = "collection_add_novel_view"
    /// "작품 추가" 화면에서 선택 확정
    case addNovelConfirmed = "collection_add_novel_confirm"
    /// "서재에서 추가" 화면 진입
    case myLibrarySelectViewed = "collection_my_library_select_view"
    /// "서재에서 추가" 화면에서 선택 확정
    case myLibrarySelectConfirmed = "collection_my_library_select_confirm"
}
