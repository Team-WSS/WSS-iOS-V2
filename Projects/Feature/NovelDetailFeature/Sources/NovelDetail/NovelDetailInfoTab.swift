//
//  NovelDetailInfoTab.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

/// 정보 탭: 작품 소개(펼침) / 작품 보러가기(플랫폼) / 독자들의 감상평(매력포인트·키워드·읽기 상태 그래프).
/// 감상평 하위 요소는 각각 값이 없으면 표시하지 않고, 전부 없으면 빈 상태로 대체한다.
struct NovelDetailInfoTab: View {

    let information: NovelInformation
    @Binding var isDescriptionExpanded: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 35)
            descriptionSection
            thinDivider
            if !information.platforms.isEmpty {
                Spacer().frame(height: 35)
                platformSection
                Spacer().frame(height: 35)
                thickDivider
            }
            Spacer().frame(height: 35)
            reviewSummarySection
            Spacer().frame(height: 70)
        }
        .background(Color.wssWhite)
    }

    // MARK: - 작품 소개

    private var descriptionSection: some View {
        VStack(spacing: 0) {
            sectionTitle("작품 소개")
            Spacer().frame(height: 10)
            Text(information.description)
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray300.opacity(0.8))
                .lineLimit(isDescriptionExpanded ? nil : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            expandButton
        }
    }

    /// 소개 펼침/접기. 접힘 상태는 3줄 제한 + 아래 방향 chevron(펼치면 반전).
    private var expandButton: some View {
        Button {
            isDescriptionExpanded.toggle()
        } label: {
            WSSImage.icChevronDown.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(isDescriptionExpanded ? 180 : 0))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 작품 보러가기

    private var platformSection: some View {
        VStack(spacing: 0) {
            sectionTitle("작품 보러가기")
            Spacer().frame(height: 15)
            HStack(spacing: 0) {
                ForEach(information.platforms, id: \.name) { platform in
                    Button {
                        openURL(platform.url)
                    } label: {
                        platformIcon(platform)
                    }
                    .buttonStyle(.plain)

                    if platform.name != information.platforms.last?.name {
                        Spacer().frame(width: 16)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    private func platformIcon(_ platform: NovelPlatform) -> some View {
        AsyncImage(url: platform.image) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Color.wssGray70
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 독자들의 감상평

    private var hasAnyReviewSummary: Bool {
        !information.attractivePoints.isEmpty
            || !information.keywords.isEmpty
            || information.dominantReadStatus != nil
    }

    @ViewBuilder
    private var reviewSummarySection: some View {
        if hasAnyReviewSummary {
            VStack(spacing: 0) {
                sectionTitle("독자들의 감상평")

                if !information.attractivePoints.isEmpty {
                    Spacer().frame(height: 15)
                    attractivePointBox
                }

                if !information.keywords.isEmpty {
                    Spacer().frame(height: 10)
                    keywordList
                }

                if let dominant = information.dominantReadStatus {
                    Spacer().frame(height: 40)
                    thinDivider
                    Spacer().frame(height: 35)
                    readingStatusGraph(dominant: dominant)
                }
            }
        } else {
            // 평가 요약이 하나도 없으면 빈 상태 — 제목도 디자인대로 "독자들의 평가"로 바뀐다.
            VStack(spacing: 0) {
                sectionTitle("독자들의 평가")
                Spacer().frame(height: 40)
                NovelDetailEmptyView(message: "아직 평가가 없어요\n최초로 남겨보세요!")
            }
        }
    }

    /// "캐릭터, 관계, 필력(이)가 매력적인 작품이에요" — 포인트 나열만 포인트 컬러.
    private var attractivePointBox: some View {
        (
            Text(information.attractivePoints.map(\.displayName).joined(separator: ", "))
                .foregroundColor(Color.wssPrimary100)
            + Text("(이)가 매력적인 작품이에요")
                .foregroundColor(Color.wssBlack)
        )
        .applyWSSFont(.title3)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(Color.wssGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var keywordList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(information.keywords) { novelKeyword in
                    CountedKeywordChip(keyword: novelKeyword.keyword.name, count: novelKeyword.count)
                    if novelKeyword.id != information.keywords.last?.id {
                        Spacer().frame(width: 6)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 읽기 상태 그래프

    private static let graphStatusOrder = ReadingStatus.novelDetailDisplayOrder

    private func readingStatusGraph(dominant: (status: ReadingStatus, count: Int)) -> some View {
        VStack(spacing: 0) {
            // "130명이 작품을 \n같이 보고 있어요" — 인원수만 포인트 컬러, 문구는 우세 상태 표현을 재사용.
            (
                Text("\(dominant.count)명")
                    .foregroundColor(Color.wssPrimary100)
                + Text("이 작품을 \n\(dominant.status.graphSectionTitle)")
                    .foregroundColor(Color.wssBlack)
            )
            .applyWSSFont(.title1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            Spacer().frame(height: 30)

            HStack(spacing: 0) {
                Spacer()
                ForEach(Self.graphStatusOrder, id: \.self) { status in
                    graphColumn(status: status, isDominant: status == dominant.status)
                    if status != Self.graphStatusOrder.last {
                        Spacer().frame(width: 60)
                    }
                }
                Spacer()
            }
        }
    }

    private func graphColumn(status: ReadingStatus, isDominant: Bool) -> some View {
        let count = information.readingStatusCount[status] ?? 0
        let maxCount = max(information.readingStatusCount.values.max() ?? 1, 1)
        // 트랙 100pt 기준 비율 채움. 0이 아니면 최소 10pt는 보이게(디자인의 최소 높이).
        let fillHeight: CGFloat = count == 0 ? 0 : max(10, CGFloat(count) / CGFloat(maxCount) * 100)

        return VStack(spacing: 0) {
            Text("\(count)")
                .applyWSSFont(.body5)
                .foregroundStyle(isDominant ? Color.wssPrimary200 : Color.wssGray200)
            Spacer().frame(height: 8)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.wssGray50)
                UnevenRoundedRectangle(
                    topLeadingRadius: fillHeight >= 100 ? 10 : 0,
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: fillHeight >= 100 ? 10 : 0
                )
                .fill(isDominant ? Color.wssPrimary100 : Color.wssGray70)
                .frame(height: fillHeight)
            }
            .frame(width: 50, height: 100)
            Spacer().frame(height: 8)
            Text(status.statusName)
                .applyWSSFont(.body2)
                .foregroundStyle(isDominant ? Color.wssPrimary200 : Color.wssGray200)
        }
    }

    // MARK: - 공통

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .applyWSSFont(.title1)
            .foregroundStyle(Color.wssBlack)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.wssGray70)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    private var thickDivider: some View {
        Rectangle()
            .fill(Color.wssGray50)
            .frame(height: 7)
            .frame(maxWidth: .infinity)
    }
}
