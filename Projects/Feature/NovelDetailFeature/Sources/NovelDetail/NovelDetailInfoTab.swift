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

    /// 접힘 상태에서 보일 소개글 3줄의 실측 높이(펼침 애니메이션의 클램프 기준).
    /// `lineLimit`을 애니메이션하면 접을 때 4번째 줄 이하가 뚝 사라져 부자연스럽다 —
    /// KeywordFeature 카테고리 접기(`SearchKeywordView`)처럼 텍스트는 늘 전문을 그린 채
    /// **프레임 높이만** 3줄↔전체로 애니메이션하고 `.clipped()`로 넘치는 줄을 부드럽게 여닫는다.
    /// 3줄 높이는 Dynamic Type에 따라 달라져 고정하지 않고 숨은 3줄 사본을 GeometryReader로 실측한다
    /// (초기값 67.5 = body2 줄높이 22.5 × 3 — 첫 프레임 깜빡임 방지용 seed, 실측이 곧 덮어쓴다).
    @State private var collapsedDescriptionHeight: CGFloat = 67.5

    private var descriptionSection: some View {
        VStack(spacing: 0) {
            sectionTitle("작품 소개")
            Spacer().frame(height: 10)
            Text(information.description)
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssGray300.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: isDescriptionExpanded ? nil : collapsedDescriptionHeight, alignment: .top)
                .clipped()
                .background(alignment: .top) { descriptionHeightProbe }
                .padding(.horizontal, 20)
            expandButton
        }
    }

    /// 숨은 3줄 사본 — 보이는 소개글과 같은 폭·폰트로 그려 그 높이를 접힘 클램프 값으로 실측한다.
    /// 소개글이 바뀌면(재진입 조용한 갱신 등) 높이가 달라져 `onChange`로 다시 잡는다.
    private var descriptionHeightProbe: some View {
        Text(information.description)
            .applyWSSFont(.body2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { collapsedDescriptionHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, height in
                            collapsedDescriptionHeight = height
                        }
                }
            )
            .hidden()
    }

    /// 소개 펼침/접기. 접힘 상태는 3줄 클램프 + 아래 방향 chevron(펼치면 반전).
    /// 애니메이션은 `.animation(value:)`이 아니라 상태 변경을 `withAnimation`으로 감싸 건다
    /// (KeywordFeature 접기와 동일 — 프레임 높이·chevron 회전이 한 트랜잭션에서 함께 움직인다).
    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isDescriptionExpanded.toggle()
            }
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(information.platforms, id: \.name) { platform in
                        Button {
                            openURL(platform.url)
                        } label: {
                            platformIcon(platform)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }

    private func platformIcon(_ platform: NovelPlatform) -> some View {
        // 플랫폼 아이콘도 목록(ForEach)처럼 반복 렌더돼 raw AsyncImage면 캐시 히트에도 placeholder가
        // 번쩍인다 → WSSAsyncImage로 인메모리 캐시 공유. 원래 동작(로딩 중·실패 모두 회색)을 유지하려
        // placeholder는 isLoading을 구분하지 않고 Color.wssGray70만 그린다.
        WSSAsyncImage(url: platform.image) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: { _ in
            Color.wssGray70
        }
        .frame(width: 48, height: 48)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }
    // MARK: - 독자들의 감상평

    /// "독자들의 감상평"의 **내용**은 매력포인트·키워드다 — 읽기 상태 그래프는 제목을 공유하지 않는 별도 섹션.
    /// 그래서 이 둘이 다 비면 그래프가 있어도 제목까지 통째로 감춘다(제목만 덩그러니 남는 걸 막는다).
    private var hasReviewContent: Bool {
        !information.attractivePoints.isEmpty || !information.keywords.isEmpty
    }

    private var hasAnyReviewSummary: Bool {
        hasReviewContent || information.dominantReadStatus != nil
    }

    @ViewBuilder
    private var reviewSummarySection: some View {
        if hasAnyReviewSummary {
            VStack(spacing: 0) {
                if hasReviewContent {
                    sectionTitle("독자들의 감상평")

                    if !information.attractivePoints.isEmpty {
                        Spacer().frame(height: 15)
                        attractivePointBox
                    }

                    if !information.keywords.isEmpty {
                        Spacer().frame(height: 10)
                        keywordList
                    }
                }

                if let dominant = information.dominantReadStatus {
                    // 구분선은 위에 감상평이 실제로 있을 때만 — 그래프만 있으면 나눌 대상이 없다.
                    if hasReviewContent {
                        Spacer().frame(height: 40)
                        thinDivider
                        Spacer().frame(height: 35)
                    }
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
