//
//  WSSLibraryGridCell.swift
//  WSSComponent
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem

/// 서재류 작품 그리드 셀 — 표지(읽기상태 뱃지·관심 하트 오버레이) + 제목 + 내 별점 + 날짜.
/// `LibraryFeature`의 내 서재/타유저 서재 그리드와 `CollectionFeature`의 "서재에서 추가" 화면이
/// 완전히 같은 셀을 쓰게 돼 공용화했다(2026-08, 원본은 `LibraryFeature`의 `LibraryGridCell`) — 두
/// 화면의 유일한 차이가 선택 서클 오버레이뿐이라 `isSelected`(옵셔널)로 흡수한다.
///
/// **폭은 부모가 정한다** — 그리드 열 너비를 그대로 채우고 표지 높이는 108:160 비율로 정해진다.
/// 표지 아래 정보 스택(제목·별점·날짜)은 **고정 높이**다 — 제목 줄 수(1~2)·별점/날짜 유무로 셀마다
/// 자연 높이가 갈리면 `LazyVGrid` 행이 어긋난다(`LibraryFeature`에서 실제로 겪음). 스택 **안**은
/// 자연스럽게 흐르게 두고 스택 **자체만** 고정한다.
///
/// 이 컴포넌트는 탭 동작을 직접 갖지 않는다(순수 표시 뷰) — 서재는 셀 전체를 `Button`으로,
/// 컬렉션은 `.onTapGesture`로 감싸는 등 호출부마다 탭 처리 방식이 달라서다. 호출부가
/// `.contentShape(Rectangle())` + `Button`/`onTapGesture`를 얹는다.
public struct WSSLibraryGridCell: View {

    private enum Metric {
        /// 표지 비율(디자인 108×160) — 폭은 그리드 열 너비를 따라가고 높이는 비율로 정해진다.
        static let thumbnailAspectRatio: CGFloat = 108.0 / 160.0
        /// 표지 아래 정보 스택의 **고정 높이**(제목 2줄 + 별점 + 날짜를 담는 크기).
        static let infoHeight: CGFloat = 65
        static let starSize: CGFloat = 9
        static let statusBadgeWidth: CGFloat = 49
        static let selectIconSize: CGFloat = 24
        static let selectIconInset: CGFloat = 8
    }

    private let thumbnailImage: URL?
    private let title: String
    private let readingStatus: ReadingStatus?
    private let myRating: Double?
    /// 이미 포맷된 표시 문자열(예: "24.01.03" / "24.01.03 ~ 25.03.08") — 이 컴포넌트는 `ReadingPeriod`를
    /// 모른다(표기는 호출부 몫, `ReadingPeriod.displayText`로 만들어 넘긴다).
    private let dateText: String?
    private let isInterested: Bool
    /// `nil`이면 선택 UI 자체를 그리지 않는다(서재처럼 순수 열람용 그리드). 값이 있으면 그 상태로
    /// 선택 서클(`icSelectNovelDefault`/`icSelectNovelSelected`, `WSSNovelSelectRow`와 동일 에셋)을 그린다.
    private let isSelected: Bool?

    public init(
        thumbnailImage: URL?,
        title: String,
        readingStatus: ReadingStatus? = nil,
        myRating: Double? = nil,
        dateText: String? = nil,
        isInterested: Bool = false,
        isSelected: Bool? = nil
    ) {
        self.thumbnailImage = thumbnailImage
        self.title = title
        self.readingStatus = readingStatus
        self.myRating = myRating
        self.dateText = dateText
        self.isInterested = isInterested
        self.isSelected = isSelected
    }

    public var body: some View {
        VStack(spacing: 0) {
            thumbnail
            Spacer().frame(height: 6)
            infoStack
        }
    }
}

// MARK: - Sections

private extension WSSLibraryGridCell {

    /// 제목·별점·날짜. 내용은 자연스럽게 위에서부터 흐르고, 스택 자체만 고정 높이를 차지한다.
    var infoStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .applyWSSFont(.body4, color: .wssBlack, alignment: .leading)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let myRating {
                Spacer().frame(height: 2)
                starRow(rating: Float(myRating))
            }
            if let dateText {
                Spacer().frame(height: 4)
                Text(dateText)
                    .applyWSSFont(.label2, color: .wssGray200)
                    .lineLimit(1)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Metric.infoHeight,
            maxHeight: Metric.infoHeight,
            alignment: .topLeading
        )
    }

    /// 표지 — 열 너비에 맞춰 비율(108:160)대로 커지고, 좌하단 읽기 상태 뱃지·우하단 관심 하트·
    /// 우상단 선택 서클(있으면)을 얹는다. 표지 로드·캐시·빈 표지 폴백은 `WSSNovelCoverImage`가 담당.
    /// ⚠️ 비율은 **파라미터로 넘긴다** — 밖에서 `.aspectRatio`를 걸면 `scaledToFill`과 충돌해 표지가 좁아진다.
    var thumbnail: some View {
        WSSNovelCoverImage(url: thumbnailImage, aspectRatio: Metric.thumbnailAspectRatio, placeholderStyle: .grid)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            // 잘린 그림 밖 원본 크기로 hit-test 영역이 남지 않게 명시(스크롤·셀 탭 간섭 예방).
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
                if let readingStatus {
                    statusBadge(readingStatus)
                        .padding(.leading, 6)
                        .padding(.bottom, 8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isInterested {
                    WSSImage.icHeartFilledStroke.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .padding(.trailing, 9.5)
                        .padding(.bottom, 9.5)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let isSelected {
                    selectCircle(isSelected: isSelected)
                        .padding(Metric.selectIconInset)
                }
            }
    }

    /// `WSSNovelSelectRow`와 동일한 크로스페이드+스프링 — 정본 패턴 그대로.
    func selectCircle(isSelected: Bool) -> some View {
        ZStack {
            WSSImage.icSelectNovelDefault.swiftUIImage
                .opacity(isSelected ? 0 : 1)
                .scaleEffect(isSelected ? 0.85 : 1)
            WSSImage.icSelectNovelSelected.swiftUIImage
                .opacity(isSelected ? 1 : 0)
                .scaleEffect(isSelected ? 1 : 0.6)
        }
        .frame(width: Metric.selectIconSize, height: Metric.selectIconSize)
        .animation(.spring(response: 0.32, dampingFraction: 0.6), value: isSelected)
    }

    func statusBadge(_ status: ReadingStatus) -> some View {
        Text(status.statusName)
            .applyWSSFont(.label2, color: .wssWhite)
            .frame(width: Metric.statusBadgeWidth)
            .padding(.vertical, 4)
            .background(status.tagBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// 내 별점 5개 표기 — 0.5 단위 반별. (도메인 `Rating`은 0.5~5.0만 허용)
    func starRow(rating: Float) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                starImage(at: index, rating: rating)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.starSize, height: Metric.starSize)
            }
        }
    }

    func starImage(at index: Int, rating: Float) -> Image {
        let position = Float(index)
        if rating >= position + 1 {
            return WSSImage.icSmallStarFilled.swiftUIImage
        } else if rating >= position + 0.5 {
            return WSSImage.icSmallStarHalf.swiftUIImage
        } else {
            return WSSImage.icSmallStarEmpty.swiftUIImage
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        WSSLibraryGridCell(
            thumbnailImage: nil,
            title: "당신의 이해를 돕기 위하여",
            readingStatus: .watching,
            myRating: 4.0,
            dateText: "24.01.03 ~ 25.03.08",
            isInterested: true
        )
        WSSLibraryGridCell(
            thumbnailImage: nil,
            title: "광마회귀",
            isInterested: false,
            isSelected: true
        )
    }
    .frame(width: 232)
}
