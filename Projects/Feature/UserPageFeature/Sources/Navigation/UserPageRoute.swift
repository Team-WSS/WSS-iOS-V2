//
//  UserPageRoute.swift
//  UserPageFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 타유저 프로필(push 화면)이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
/// 차단 완료(`onUserBlocked` — pop 후 토스트용 결과 콜백)는 화면 전환 "의도"가 아니라 여기 없다.
public enum UserPageRoute {
    /// 이 유저의 서재 — "서재" 블록(화살표 아이콘·통계 행) 탭.
    case userLibrary
    /// 이 유저의 전체 피드 목록 — "활동기록 더보기" 탭. 이 화면이 이미 로드해둔 프로필 값
    /// (닉네임·프로필 이미지)을 실어 보내 App이 따로 조회할 필요가 없다(#201).
    case userFeedList(userID: UserID, nickname: String, profileImage: URL?)
    /// 컬렉션 상세 — 컬렉션 미리보기 항목 탭.
    case collectionDetail(CollectionID)
    /// 이 유저의 컬렉션 목록 — 컬렉션 섹션 헤더 탭(컬렉션이 있을 때만 — 없으면 VM이 토스트).
    case collectionList
}
