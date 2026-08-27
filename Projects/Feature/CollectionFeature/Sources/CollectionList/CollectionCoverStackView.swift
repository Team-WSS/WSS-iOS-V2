//
//  CollectionCoverStackView.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import DesignSystem
import WSSComponent

/// 컬렉션 목록 카드의 표지 스택 — `CollectionCard.recentNovels`(최대 5개)를 가로로 겹쳐 그린다.
/// 마이페이지 미리보기(대표 표지 1장, `UserPageFeature.CollectionSection`)와는 시각 패턴이 달라
/// 별개 컴포넌트다 — 각자 자기 모듈에 1곳씩만 쓰여 승격 근거가 없다(`CollectionFeature/CLAUDE.md`).
struct CollectionCoverStackView: View {

    private let recentNovels: [CollectionNovel]

    init(recentNovels: [CollectionNovel]) {
        self.recentNovels = recentNovels
    }

    private enum Metric {
        static let coverWidth: CGFloat = 74
        static let coverHeight: CGFloat = 108
        static let cornerRadius: CGFloat = 8
        /// `CollectionCard.recentNovels`는 최대 5개까지만 온다(문서 참고) — 실제 작품이 그보다
        /// 적어도 슬롯 자체는 항상 5개로 고정한다(사용자 확정, 2026-08-21). 모자란 슬롯은
        /// `WSSNovelCoverImage(url: nil)`의 기본 표지 폴백으로 채운다 — "몇 개 들었나"를 표지 개수로
        /// 세지 않게 하려는 디자인 의도. 작품 수는 카드 부제(`작품 N`)로만 알린다.
        static let slotCount = 5
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: spacing(for: proxy.size.width)) {
                ForEach(0..<Metric.slotCount, id: \.self) { index in
                    cover(url: index < recentNovels.count ? recentNovels[index].thumbnailImage : nil)
                        // Figma는 맨 왼쪽(표시 순서 첫 작품)이 맨 위로 그려진다 — DOM에서 그
                        // 카드가 마지막에 그려짐(나중 그려질수록 위). SwiftUI HStack은 기본이
                        // 반대(나중 배치=오른쪽=위)라 zIndex로 순서를 뒤집어야 한다.
                        .zIndex(Double(Metric.slotCount - index))
                }
            }
        }
        .frame(height: Metric.coverHeight)
    }

    /// 슬롯이 항상 5개로 고정이라, 카드 콘텐츠 폭(`availableWidth`, 카드 자체가 이미 좌우 17pt 패딩을
    /// 갖고 있다)에 맞춰 간격을 계산해 **스택 전체가 그 폭을 정확히 채우게** 한다 — 그래야 오른쪽에
    /// 남는 빈 여백 없이 카드 패딩과 대칭을 이룬다(Figma 실측 375pt 기준 등차 58px는 그 폭에서만
    /// 맞고, 더 넓은 기기에선 오른쪽에 여백이 남았다 — 실사용자 리포트로 발견해 동적 계산으로 바꿨다).
    private func spacing(for availableWidth: CGFloat) -> CGFloat {
        let step = (availableWidth - Metric.coverWidth) / CGFloat(Metric.slotCount - 1)
        return -(Metric.coverWidth - step)
    }

    // 크기 고정 자리라 aspectRatio 파라미터 없이 .frame으로 직접 크기를 준다(WSSNovelSelectRow와
    // 동일 패턴 — `WSSComponent/CLAUDE.md` 정본, 열 너비를 따라가는 그리드 셀과는 다른 경우다).
    private func cover(url: URL?) -> some View {
        WSSNovelCoverImage(url: url)
            .frame(width: Metric.coverWidth, height: Metric.coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .shadow(color: Color.black.opacity(0.1), radius: 7.5, x: 0, y: 2)
    }
}
