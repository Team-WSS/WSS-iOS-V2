//
//  TabBarVisibility.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

extension View {
    /// 탭에서 push된 화면이 하단 탭바를 가릴 때 쓴다.
    ///
    /// ⚠️ `.toolbar(.hidden, for: .tabBar)`를 **pop 시 파괴되는 destination 뷰**(각 Root의
    /// `.navigationDestination` 클로저 안)에 붙이면, root 복귀 시 destination이 스택에서 빠진
    /// **뒤에야** SwiftUI가 탭바 복원을 별도 단계로 처리해 탭바가 뒤늦게 붙는다 — 홈이 "탭바 없이"
    /// 먼저 그려졌다가 ~수백 ms 뒤 탭바가 올라오며 콘텐츠가 튀는 게 실측됐다(iOS 26 Liquid Glass에서
    /// 더 두드러짐). 그래서 숨김 여부를 **항상 살아 있는 `NavigationStack` 컨테이너**에 걸어
    /// (`hidden`은 `path.isEmpty`로 판단), modifier 호스트가 파괴되지 않고 **값만** 바뀌게 한다 —
    /// 탭바 복원이 뷰 teardown이 아니라 값 변화로 처리돼 pop과 더 잘 동기화된다.
    ///
    /// 각 탭 Root는 `.navigationDestination` 클로저 안이 아니라 `NavigationStack { … }` 호출부에
    /// `.hidesTabBar(when: !path.isEmpty)`로 건다. 새 탭 Root를 추가할 때도 이 자리에 붙일 것.
    func hidesTabBar(when hidden: Bool) -> some View {
        toolbar(hidden ? .hidden : .visible, for: .tabBar)
    }
}
