//
//  FeedListInvalidation.swift
//  WSS-iOS
//
//  Created by YunhakLee on 9/3/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Observation

/// 피드 작성 완료를 **피드 탭 목록**에 알리는 앱 전역 신호(V1 `NotificationName.feedEdited` parity).
///
/// 피드 탭 목록(`SosoFeedView`)은 재진입에 목록을 다시 받지 않는다(스크롤·길이 보존 — 다녀온 셀만 상세로
/// 동기화). 그래서 **새 글**은 이 신호로만 목록에 들어온다 — 4탭 Root의 작성 화면 `onSubmitted`가
/// `markFeedCreated()`를 부르고, `FeedRootView`가 `feedCreatedVersion`을 `makeSosoFeedView`에 넘긴다.
/// `@Observable`이라 값이 바뀌면 다른 탭에 있어도 `FeedRootView.body`가 재평가되고(TabView가 4탭을
/// 계속 mount), 목록이 미리 재로드돼 피드 탭으로 왔을 때 이미 새 글이 맨 위에 있다.
///
/// `CrossScreenFeedback`(완료 토스트)과 역할이 다르다 — 그쪽은 "그 탭에서 한 번 보여주는 피드백", 이쪽은
/// "피드 탭 목록의 데이터 무효화". ⚠️ **수정 완료(`makeEditFeedView`의 `onSubmitted`)에는 붙이지 말 것** —
/// 수정은 목록이 떠나기 전 기억한 셀을 상세로 다시 맞추는 방식이라, 여기서 재로드하면 스크롤이 최상단으로 튄다.
@MainActor
@Observable
final class FeedListInvalidation {

    /// 단조 증가 카운터 — Feature는 이 Int만 받아 `onChange`로 반응한다(값 자체엔 의미 없음).
    private(set) var feedCreatedVersion = 0

    func markFeedCreated() {
        feedCreatedVersion += 1
    }
}
