//
//  LibraryPageSizePolicy.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서재 목록을 한 번에 몇 개 요청할지 정하는 정책.
///
/// 화면이 `size`를 정하는 구조라 계산이 Feature에 흩어지기 쉬운데, **이 계산이 이번 기능에서 가장
/// 틀리기 쉬운 부분**(보던 개수·delta·상한이 얽힌다)이라 순수 함수로 내려 테스트로 고정한다.
/// 상한이 서버 제약이라는 점도 Feature보다 여기가 제자리다.
public enum LibraryPageSizePolicy {

    /// 무한 스크롤 한 페이지 크기.
    public static let pageSize = 20

    /// 한 요청으로 받을 수 있는 개수의 서버 상한.
    ///
    /// ⚠️ 이 값은 **실측으로 확정된 게 아니다** — dev 서버는 `size=101·150·500`에도 400이 아니라 200을
    /// 주는데(2026-08-18), 100을 넘겼을 때 잘라서 주는지 요청대로 주는지는 100건 넘는 서재가 없어
    /// 구분하지 못했다. 어느 쪽이든 `nextCursor`가 실제 응답 기준이라 커서 정합성은 깨지지 않으므로,
    /// **클라가 먼저 잘라 동작을 결정론적으로 만든** 상태다.
    public static let maxSize = 100

    /// 재진입 갱신의 1차 요청 크기 — **보고 있던 개수를 그대로** 받되 상한에서 자른다.
    ///
    /// 보던 개수보다 적게 받으면 목록이 짧아져 스크롤이 위로 튄다(등록 최신순이면 새 작품이 앞에 붙어
    /// 그만큼 뒤가 밀려나기 때문). 아직 아무것도 못 받았으면 첫 페이지 크기로 시작한다.
    public static func refreshSize(loadedCount: Int) -> Int {
        min(max(loadedCount, pageSize), maxSize)
    }

    /// 재진입 갱신의 2차 요청 크기 — 자리를 비운 사이 **늘어난 만큼(delta)** 만 이어 받는다.
    /// 이어받을 게 없으면 nil(= 2차 요청 없음).
    ///
    /// delta는 "지금 서버의 전체 수 - 직전 전체 수"라 **1차 응답을 받아야만** 알 수 있다 —
    /// 갱신이 2단계인 이유가 이것이다. 삭제로 delta가 0 이하면 목록이 짧아질 이유가 없고,
    /// 더 받을 페이지가 없으면(`hasNext == false`) 이어붙일 것도 없다.
    public static func followUpSize(
        previousTotalCount: Int,
        newTotalCount: Int,
        hasNext: Bool
    ) -> Int? {
        guard hasNext else { return nil }

        let delta = newTotalCount - previousTotalCount
        guard delta > 0 else { return nil }

        return min(delta, maxSize)
    }
}
