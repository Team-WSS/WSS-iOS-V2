//
//  LibraryListCell.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 리스트 모드 셀 — 뱃지+날짜 / 썸네일+정보(제목·별점·매력포인트) / 키워드 칩 행.
// 디자인 정본은 "한줄평 뺌" 버전(31733:94684) — 한줄평 없음.
struct LibraryListCell: View {

    let novel: LibraryNovel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasBadgeRow {
                badgeRow
                Spacer().frame(height: 6)
            }
            infoRow
            if let keywords = novel.userReview?.keywords, !keywords.isEmpty {
                Spacer().frame(height: 8)
                keywordRow(keywords)
            }
        }
    }

    private var hasBadgeRow: Bool {
        novel.userReview?.readingStatus != nil
    }

    // MARK: - Rows

    /// 상태 뱃지(고정폭 60) + 날짜.
    private var badgeRow: some View {
        HStack(spacing: 0) {
            if let status = novel.userReview?.readingStatus {
                Text(status.statusName)
                    .applyWSSFont(.label2, color: .wssWhite)
                    .frame(width: 60, height: 18)
                    .background(status.tagBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            if let dateText = novel.userReview?.period?.displayText {
                Spacer().frame(width: 16)
                Text(dateText)
                    .applyWSSFont(.body5, color: .wssGray300)
            }
        }
    }

    private var infoRow: some View {
        HStack(alignment: .top, spacing: 0) {
            thumbnail
            Spacer().frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 5)
                Text(novel.title)
                    .applyWSSFont(.title2, color: .wssBlack, alignment: .leading)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                Spacer().frame(height: 2)
                ratingRow
                if let points = novel.userReview?.attractivePoint, !points.isEmpty {
                    Spacer().frame(height: 6)
                    attractivePointRow(points)
                }
            }
        }
    }

    /// 표지 로드·캐시·빈 표지 폴백은 `WSSNovelCoverImage`가 담당(토글·재활용 시 번쩍임 방지).
    private var thumbnail: some View {
        WSSNovelCoverImage(url: novel.thumbnailImage)
        .frame(width: 60, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomTrailing) {
            if novel.isInterested {
                WSSImage.icHeartFilledStroke.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
        }
    }

    /// 내 별점(빨강·Medium)·전체 별점(회색·Regular). 두 별점 다 "없음(0.0)"이면 자리는 지키되 감춘다 —
    /// 내 별점은 매핑에서 이미 nil(`Rating`이 0.5 미만을 거부)이라 `if let`으로 빠지고,
    /// 전체 별점(`Float` 평균)은 0.0을 여기서 `opacity`로 숨긴다(레이아웃 유지가 목적이라 제거가 아님).
    private var ratingRow: some View {
        HStack(spacing: 10) {
            if let rating = novel.userReview?.rating {
                HStack(spacing: 5) {
                    HStack(spacing: 2) {
                        WSSImage.icSmallStarFilled.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text(ratingText(Float(rating.value)))
                            .applyWSSFont(.body5_2, color: .wssSecondary100)
                    }
                    Text("내 별점")
                        .applyWSSFont(.body5, color: .wssGray300)
                }
            }
            HStack(spacing: 5) {
                HStack(spacing: 2) {
                    WSSImage.icSmallStarEmpty.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssGray200)
                        .frame(width: 12, height: 12)
                    Text(ratingText(novel.rating))
                        .applyWSSFont(.body5, color: .wssGray200)
                }
                Text("전체 별점")
                    .applyWSSFont(.body5, color: .wssGray200)
            }
            .opacity(hasNovelRating ? 1 : 0)
            .accessibilityHidden(!hasNovelRating)
        }
        .frame(height: 17)
    }

    /// 전체 별점 0.0 = "아직 아무도 평가 안 함" → 내 별점(userNovelRating 0.0이 매핑에서 nil로 걸러짐)이
    /// 숨는 것과 같은 취급. 평균값이 `Float`라 `Rating`(0.5 단위)으로 못 올려 표기 판정만 View가 한다.
    private var hasNovelRating: Bool { novel.rating > 0 }

    /// 매력포인트 — 아이콘 12px + 이름, 항목 사이 2px 점 구분자.
    private func attractivePointRow(_ points: [AttractivePoint]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                if index > 0 {
                    Circle()
                        .fill(Color.wssPrimary100)
                        .frame(width: 2, height: 2)
                }
                HStack(spacing: 3) {
                    point.iconImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssPrimary100)
                        .frame(width: 12, height: 12)
                    Text(point.displayName)
                        .applyWSSFont(.body5, color: .wssGray300)
                }
            }
        }
        .frame(height: 23)
    }

    /// 키워드 칩 — 뷰포트는 화면 끝까지 확장하고, 칩 시작·끝 정렬만 콘텐츠 마진으로 맞춘다.
    private func keywordRow(_ keywords: [Keyword]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(keywords) { keyword in
                    Text(keyword.name)
                        .applyWSSFont(.body5, color: .wssGray200)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.wssPrimary20)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .fixedSize()
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        // 셀의 공통 좌우 여백은 유지하되, 키워드 스크롤 영역만 화면 끝까지 넓힌다.
        .padding(.horizontal, -20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ratingText(_ value: Float) -> String {
        String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 28) {
        LibraryListCell(
            novel: LibraryNovel(
                id: NovelID(1),
                title: "당신의 이해를 돕기 위하여",
                thumbnailImage: nil,
                rating: 4.2,
                isInterested: true,
                userReview: UserNovelReview(
                    readingStatus: .watching,
                    rating: try? Rating(4.0),
                    attractivePoint: [.character, .vibe],
                    period: nil,
                    keywords: [Keyword(id: KeywordID(1), name: "빙의")]
                ),
                writtenFeeds: []
            )
        )
        // 평가 없는 작품 — 뱃지·매력포인트·키워드 행이 숨고, 전체 별점(0.0)도 감춰져 별점 행이 빈 채 자리만 남는다.
        LibraryListCell(
            novel: LibraryNovel(
                id: NovelID(2),
                title: "전지적 독자 시점",
                thumbnailImage: nil,
                rating: 0.0,
                isInterested: true,
                userReview: nil,
                writtenFeeds: []
            )
        )
        // 내 별점은 있지만 전체 별점(0.0)만 없는 작품 — 왼쪽 내 별점만 보이고 전체 별점 자리는 비워둔다.
        LibraryListCell(
            novel: LibraryNovel(
                id: NovelID(3),
                title: "재혼 황후",
                thumbnailImage: nil,
                rating: 0.0,
                isInterested: false,
                userReview: UserNovelReview(
                    readingStatus: .watched,
                    rating: try? Rating(4.5),
                    attractivePoint: [.relationship],
                    period: nil,
                    keywords: []
                ),
                writtenFeeds: []
            )
        )
    }
    .padding(.horizontal, 20)
}
