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
///
/// 인디케이터 슬라이드는 `SearchFeature.DetailSearchFilterView`(`FeedFeature.SosoFeedView`와 동일 패턴)를
/// 그대로 따른다 — `matchedGeometryEffect` + 공용 `Namespace`, 선택된 탭에만 조건부로 인디케이터가
/// 존재해 선택이 바뀔 때 그 자리에서 사라지는 대신 새 위치로 미끄러진다. 인디케이터는 하단 구분선
/// (`Rectangle().fill(Color.wssGray70)`)과 **같은 `ZStack` bottom 레이어**에 겹쳐 그려 그 선 위를
/// 타고 움직이는 것처럼 보이게 한다(구분선을 먼저 깔고 탭 버튼을 그 위에 얹는 순서 — 아래에서 위로).
struct CollectionSegmentedTab: View {

    private let selectedTab: CollectionListTab
    private let onSelect: (CollectionListTab) -> Void

    @Namespace private var tabAnimation

    init(selectedTab: CollectionListTab, onSelect: @escaping (CollectionListTab) -> Void) {
        self.selectedTab = selectedTab
        self.onSelect = onSelect
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.wssGray70)
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(CollectionListTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
        }
    }

    // `Button`으로 감싼다 — `.onTapGesture`는 접근성 트리에 안 잡혀 VoiceOver·UI 자동화 모두 탭할 수
    // 없다(`WSSComponent/CLAUDE.md` 공통 함정).
    private func tabButton(_ tab: CollectionListTab) -> some View {
        let isSelected = tab == selectedTab
        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 0) {
                Text(title(for: tab))
                    .applyWSSFont(.title2, color: isSelected ? .wssBlack : .wssGray100)
                    .padding(.vertical, 12)

                ZStack {
                    if isSelected {
                        Rectangle()
                            .fill(Color.wssBlack)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "COLLECTION_LIST_TAB_INDICATOR", in: tabAnimation)
                    }
                }
                .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }

    private func title(for tab: CollectionListTab) -> String {
        switch tab {
        case .mine: "내 컬렉션"
        case .liked: "좋아요한 컬렉션"
        }
    }
}
