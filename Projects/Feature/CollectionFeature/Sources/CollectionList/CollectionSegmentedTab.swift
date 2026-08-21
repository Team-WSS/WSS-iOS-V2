//
//  CollectionSegmentedTab.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// "내 컬렉션"/"좋아요한 컬렉션" 2탭 세그먼트. `CollectionListView` 전용 — 재사용처가 이 화면 하나뿐이라
/// `WSSComponent`로 승격하지 않는다(이 레포의 "2번째 필요 시점에 승격" 관례).
struct CollectionSegmentedTab: View {

    private let selectedTab: CollectionListTab
    private let onSelect: (CollectionListTab) -> Void

    init(selectedTab: CollectionListTab, onSelect: @escaping (CollectionListTab) -> Void) {
        self.selectedTab = selectedTab
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let tabWidth = proxy.size.width / CGFloat(CollectionListTab.allCases.count)
                ZStack(alignment: .bottomLeading) {
                    HStack(spacing: 0) {
                        ForEach(CollectionListTab.allCases, id: \.self) { tab in
                            // `Button`으로 감싼다 — `.onTapGesture`는 접근성 트리에 안 잡혀 VoiceOver·UI
                            // 자동화 모두로 탭할 수 없다(`WSSComponent/CLAUDE.md` 공통 함정).
                            Button {
                                onSelect(tab)
                            } label: {
                                tabLabel(tab)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    // 인디케이터는 항상 그려두고 offset만 바꾼다 — 선택된 쪽에만 `if`로 그리고
                    // matchedGeometryEffect로 이으면 이동이 아니라 크로스페이드로 보인다
                    // (`LibraryFeature/CLAUDE.md`가 실측으로 남긴 함정, 그리드↔리스트 토글에서 재발했었다).
                    Rectangle()
                        .fill(Color.wssBlack)
                        .frame(width: tabWidth, height: 2)
                        .offset(x: indicatorOffset(tabWidth: tabWidth))
                        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .frame(height: 46)

            Rectangle()
                .fill(Color.wssGray70)
                .frame(height: 1)
        }
    }

    private func indicatorOffset(tabWidth: CGFloat) -> CGFloat {
        guard let index = CollectionListTab.allCases.firstIndex(of: selectedTab) else { return 0 }
        return CGFloat(index) * tabWidth
    }

    private func tabLabel(_ tab: CollectionListTab) -> some View {
        Text(title(for: tab))
            .applyWSSFont(.title2, color: tab == selectedTab ? .wssBlack : .wssGray100)
            .padding(.top, 12)
    }

    private func title(for tab: CollectionListTab) -> String {
        switch tab {
        case .mine: "내 컬렉션"
        case .liked: "좋아요한 컬렉션"
        }
    }
}
