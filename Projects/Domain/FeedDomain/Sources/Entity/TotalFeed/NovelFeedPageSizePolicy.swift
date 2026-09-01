//
//  NovelFeedPageSizePolicy.swift
//  FeedDomain
//
//  Created by YunhakLee on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 작품 상세 피드 목록의 재진입 갱신 요청 크기를 정하는 정책.
///
/// 재진입 갱신은 "보던 개수만큼 처음부터 다시 받아 통째로 교체"라(V1 parity) 요청 크기 계산이
/// Feature에 흩어지기 쉬운데, 상한이 서버 제약이라는 점에서 서재(`LibraryPageSizePolicy`)와 같은
/// 이유로 Domain 순수 함수로 내려 테스트로 고정한다.
public enum NovelFeedPageSizePolicy: Sendable {

    /// 한 요청으로 받을 수 있는 개수의 서버 상한.
    ///
    /// ⚠️ 서재 `LibraryPageSizePolicy.maxSize`와 같은 성격 — **실측으로 확정된 서버 값이 아니라**,
    /// 상한 초과 요청의 서버 동작(자르기/그대로 주기)이 갈릴 수 있어 **클라가 먼저 잘라 동작을
    /// 결정론적으로 만든** 값이다. 커서(`lastFeedId`)가 실제 응답의 마지막 항목 기준이라
    /// 어느 쪽이든 페이지네이션 정합성은 깨지지 않는다.
    public static let maxSize = 100

    /// 재진입 갱신의 요청 크기 — **보고 있던 개수를 그대로** 받되 상한에서 자른다.
    ///
    /// 상한에 걸리지 않는 한 이 크기로 받으면 목록 개수가 유지된다(같은 ID가 돌아와 스크롤도 안 튄다).
    /// 상한을 넘겨 본 상태(100+)에서는 목록이 100개로 줄고 나머지는 커서로 이어 받는다 — 서재와 같은
    /// 의도된 절충(누락 아님). 아직 받은 게 없으면 nil(= 기본 페이지 크기, Data가 정함 — V1과 같은 규칙).
    public static func refreshSize(loadedCount: Int) -> Int? {
        guard loadedCount > 0 else { return nil }
        return min(loadedCount, maxSize)
    }
}
