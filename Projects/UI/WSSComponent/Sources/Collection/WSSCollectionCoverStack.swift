//
//  WSSCollectionCoverStack.swift
//  WSSComponent
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 컬렉션 카드의 표지 스택 — 작품 표지를 가로로 겹쳐 그린다. 컬렉션 목록(`CollectionFeature`, 5칸)과
/// 홈 컬렉션 섹션(`HomeFeature`, 4칸)이 함께 쓴다(#283에 `CollectionFeature`에서 승격).
///
/// 도메인 타입(`CollectionNovel`)을 모르도록 표지 URL만 받는다.
public struct WSSCollectionCoverStack: View {

    private let coverURLs: [URL?]
    private let slotCount: Int

    /// - Parameters:
    ///   - coverURLs: 표시 순서대로의 표지. `slotCount`를 넘는 뒤쪽은 버린다.
    ///   - slotCount: 슬롯 수. 작품이 모자라도 슬롯은 항상 이 개수로 고정하고, 남는 칸은
    ///     `WSSNovelCoverImage(url: nil)`의 기본 표지로 채운다 — "몇 개 들었나"를 표지 개수로 세지 않게 하려는
    ///     디자인 의도(사용자 확정, 2026-08-21). 작품 수는 카드 부제(`작품 N`)로만 알린다.
    public init(coverURLs: [URL?], slotCount: Int) {
        self.coverURLs = coverURLs
        self.slotCount = max(slotCount, 1)
    }

    private enum Metric {
        static let coverWidth: CGFloat = 74
        static let coverHeight: CGFloat = 108
        static let cornerRadius: CGFloat = 8
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: spacing(for: proxy.size.width)) {
                ForEach(0..<slotCount, id: \.self) { index in
                    cover(url: index < coverURLs.count ? coverURLs[index] : nil)
                        // Figma는 맨 왼쪽(표시 순서 첫 작품)이 맨 위로 그려진다 — DOM에서 그
                        // 카드가 마지막에 그려짐(나중 그려질수록 위). SwiftUI HStack은 기본이
                        // 반대(나중 배치=오른쪽=위)라 zIndex로 순서를 뒤집어야 한다.
                        .zIndex(Double(slotCount - index))
                }
            }
        }
        .frame(height: Metric.coverHeight)
    }

    /// 슬롯 수가 고정이라, 카드 콘텐츠 폭에 맞춰 간격을 계산해 **스택 전체가 그 폭을 정확히 채우게** 한다 —
    /// 그래야 오른쪽에 남는 빈 여백 없이 카드 패딩과 대칭을 이룬다(Figma 실측 375pt 기준 등차 58px는 그 폭에서만
    /// 맞고, 더 넓은 기기에선 오른쪽에 여백이 남았다 — 실사용자 리포트로 발견해 동적 계산으로 바꿨다).
    private func spacing(for availableWidth: CGFloat) -> CGFloat {
        guard slotCount > 1 else { return 0 }
        let step = (availableWidth - Metric.coverWidth) / CGFloat(slotCount - 1)
        return -(Metric.coverWidth - step)
    }

    // 크기 고정 자리라 aspectRatio 파라미터 없이 .frame으로 직접 크기를 준다(WSSNovelSelectRow와
    // 동일 패턴 — 열 너비를 따라가는 그리드 셀과는 다른 경우다).
    private func cover(url: URL?) -> some View {
        WSSNovelCoverImage(url: url)
            .frame(width: Metric.coverWidth, height: Metric.coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .shadow(color: Color.black.opacity(0.1), radius: 7.5, x: 0, y: 2)
    }
}
