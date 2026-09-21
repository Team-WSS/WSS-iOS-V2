//
//  PreferenceGenreSection.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import RecommendationDomain
import DesignSystem
import WSSComponent

/// "이 웹소설은 어때요?" — 선호장르 기반 추천 그리드.
/// 장르를 아직 고르지 않은 사용자는 목록 대신 **설정 유도 카드**를 본다(빈 상태가 아니라 별도 분기).
struct PreferenceGenreSection: View {

    let state: PreferenceGenreNovelState
    let onNovelSelected: (NovelID) -> Void
    let onSettingTapped: () -> Void

    private enum Metric {
        static let horizontalPadding: CGFloat = 20
        static let titleSpacing: CGFloat = 2
        static let sectionSpacing: CGFloat = 20

        static let columnSpacing: CGFloat = 9
        static let rowSpacing: CGFloat = 18

        static let emptyCardCornerRadius: CGFloat = 14
        static let emptyCardHorizontalPadding: CGFloat = 24
        static let emptyCardVerticalPadding: CGFloat = 20
        static let ctaCornerRadius: CGFloat = 8
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: Metric.columnSpacing),
         GridItem(.flexible(), spacing: Metric.columnSpacing)]
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionTitle
            Spacer().frame(height: Metric.sectionSpacing)

            switch state {
            case .novels(let novels) where !novels.isEmpty:
                novelGrid(novels)
            // 설정했으나 추천 0건(.novels([]))도 미설정(.noGenreSettings)과 똑같이 설정 유도 카드를 띄운다
            // (#222 V1 parity — 빈 그리드보다 행동 유도).
            case .novels, .noGenreSettings:
                settingInduceCard
            }
        }
    }
}

// MARK: - Sections

private extension PreferenceGenreSection {

    var sectionTitle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이 웹소설은 어때요? (´ヮ`)ﾉ📚")
                .applyWSSFont(.headline1, color: .wssBlack, alignment: .leading)

            Spacer().frame(height: Metric.titleSpacing)

            Text("선호장르를 기반으로 추천해드려요")
                .applyWSSFont(.body2, color: .wssGray200, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metric.horizontalPadding)
    }

    /// 셀 자체는 공용 컴포넌트(`WSSNovelGridCell`)다 — 표지 비율·정보 스택 고정 높이(72)는 거기 산다.
    /// 여기선 열 개수·좌우 여백만 정한다(셀 폭 = 열 너비 = 표지·텍스트 공통 폭).
    func novelGrid(_ novels: [PreferenceGenreNovel]) -> some View {
        LazyVGrid(columns: columns, spacing: Metric.rowSpacing) {
            ForEach(novels, id: \.novelID) { novel in
                WSSNovelGridCell(
                    thumbnailImage: novel.novelThumbnailImage,
                    title: novel.novelTitle,
                    author: novel.novelAuthors.joined(separator: ", "),
                    interestCount: novel.interestCount,
                    rating: novel.rating,
                    ratingCount: novel.ratingCount
                ) {
                    onNovelSelected(novel.novelID)
                }
            }
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }

    /// 선호장르 미설정 — 목록이 없는 게 아니라 "아직 고르지 않았다"라서 설정 화면으로 유도한다.
    var settingInduceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("로맨스, 로판, 판타지, 현판 등\n선호장르를 기반으로 웹소설을 추천해드려요!")
                .applyWSSFont(.body2, color: .wssGray200, alignment: .leading)

            Spacer().frame(height: 14)

            Button(action: onSettingTapped) {
                Text("선호장르 설정하기")
                    .applyWSSFont(.body3, color: .wssWhite)
                    .padding(.horizontal, 21)
                    .padding(.vertical, 6)
                    .background(Color.wssPrimary100)
                    .clipShape(RoundedRectangle(cornerRadius: Metric.ctaCornerRadius))
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metric.emptyCardHorizontalPadding)
        .padding(.vertical, Metric.emptyCardVerticalPadding)
        .overlay {
            RoundedRectangle(cornerRadius: Metric.emptyCardCornerRadius)
                .strokeBorder(Color.wssGray70, lineWidth: 1)
        }
        .padding(.horizontal, Metric.horizontalPadding)
    }
}
