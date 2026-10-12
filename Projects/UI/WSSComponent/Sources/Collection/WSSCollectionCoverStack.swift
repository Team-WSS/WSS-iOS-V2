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
        static let cornerRadius: CGFloat = 8
    }

    public var body: some View {
        CoverStackLayout {
            ForEach(0..<slotCount, id: \.self) { index in
                cover(url: index < coverURLs.count ? coverURLs[index] : nil)
                    // Figma는 맨 왼쪽(표시 순서 첫 작품)이 맨 위로 그려진다 — DOM에서 그
                    // 카드가 마지막에 그려짐(나중 그려질수록 위). SwiftUI는 기본이
                    // 반대(나중 배치=오른쪽=위)라 zIndex로 순서를 뒤집어야 한다.
                    .zIndex(Double(slotCount - index))
            }
        }
    }

    // 크기는 CoverStackLayout이 제안한 값을 그대로 받는다 — scaledToFill 표지가 넘치지 않도록
    // 프레임으로 그 크기에 묶은 뒤 자른다.
    private func cover(url: URL?) -> some View {
        WSSNovelCoverImage(url: url)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .shadow(color: Color.black.opacity(0.1), radius: 7.5, x: 0, y: 2)
    }
}

/// 표지를 **카드 폭에 비례해 키우고 줄여** 어느 기기에서든 같은 비율로 겹치게 배치한다.
///
/// Figma(375pt) 실측은 표지 74×108에 등차 58 — 겹침 비율 58/74를 고정하고, 슬롯들이 받은 폭을 정확히
/// 채우도록 표지 크기를 역산한다. 표지 크기를 74로 고정한 채 간격만 역산하던 예전 방식은 넓은 기기
/// (17 Pro Max의 5칸 카드)에서 간격이 양수가 돼 표지가 서로 떨어졌다(#283 실측).
/// 높이도 폭을 따라 바뀌어야 해서 `GeometryReader`(높이 고정 필요) 대신 `Layout`으로 크기를 보고한다.
private struct CoverStackLayout: Layout {

    private enum Metric {
        static let coverAspectRatio: CGFloat = 108.0 / 74.0
        /// 다음 표지까지의 거리 ÷ 표지 폭(Figma 58/74). 1보다 작아야 겹친다.
        static let stepRatio: CGFloat = 58.0 / 74.0
        /// 폭 제안이 없거나 무한대일 때 쓰는 Figma 원본 표지 폭.
        static let idealCoverWidth: CGFloat = 74
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // 폭 제안이 없거나 무한대(가로 ScrollView 등)면 높이도 무한대가 되므로 Figma 원본 크기로 답한다.
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil }
            ?? totalWidth(coverWidth: Metric.idealCoverWidth, count: subviews.count)
        let coverWidth = coverWidth(for: width, count: subviews.count)
        return CGSize(width: width, height: coverWidth * Metric.coverAspectRatio)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let coverWidth = coverWidth(for: bounds.width, count: subviews.count)
        let coverSize = ProposedViewSize(width: coverWidth, height: coverWidth * Metric.coverAspectRatio)

        for (index, subview) in subviews.enumerated() {
            let x = bounds.minX + CGFloat(index) * coverWidth * Metric.stepRatio
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: coverSize)
        }
    }

    /// 첫 표지 한 장 + 나머지마다 등차 한 칸 = 전체 폭.
    private func coverWidth(for totalWidth: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return totalWidth / (1 + CGFloat(count - 1) * Metric.stepRatio)
    }

    private func totalWidth(coverWidth: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return coverWidth * (1 + CGFloat(count - 1) * Metric.stepRatio)
    }
}
