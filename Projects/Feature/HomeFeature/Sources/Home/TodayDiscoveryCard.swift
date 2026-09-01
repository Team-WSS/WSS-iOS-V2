//
//  TodayDiscoveryCard.swift
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

/// 오늘의 발견 캐러셀 카드 한 장.
///
/// 카드 안 요소들은 디자이너가 좌표로 배치한 것이라 **`offset`으로 고정 위치를 지킨다** —
/// 제목 줄 수가 1~2줄로 달라져도 키워드 칩·표지는 제자리에 있어야 카드끼리 나란히 보인다.
struct TodayDiscoveryCard: View {

    let discovery: TodayDiscovery
    let onTapped: () -> Void

    private enum Metric {
        static let width: CGFloat = 292
        static let height: CGFloat = 362
        static let cornerRadius: CGFloat = 14
        /// 배경 표지 흐림. 구 WSSiOS는 원본 이미지에 `CIGaussianBlur` radius 8을 구웠는데, 그건
        /// **원본 픽셀 기준**이라 표지 해상도에 따라 세기가 달라진다 — SwiftUI는 렌더 크기에 걸리므로
        /// 시안과 대조해 맞춘 값이다.
        static let backdropBlurRadius: CGFloat = 8

        static let coverWidth: CGFloat = 117
        static let coverHeight: CGFloat = 171
        static let coverLeading: CGFloat = 153
        static let coverTop: CGFloat = 33
        static let coverCornerRadius: CGFloat = 5.65
        /// 시안의 `icGenre` 프레임 크기. NovelDetail(71)의 축소판이라 아이콘·인셋도 같은 비율로 줄인다.
        static let genreBackgroundSize: CGFloat = 56
        static let genreIconSize: CGFloat = 25
        static let genreIconTrailingInset: CGFloat = 3
        static let genreIconBottomInset: CGFloat = 4

        static let infoLeading: CGFloat = 19
        static let infoTop: CGFloat = 33
        static let infoWidth: CGFloat = 120

        static let chipTop: CGFloat = 156
        static let chipSpacing: CGFloat = 4
        /// 시안이 두 줄까지만 자리를 잡아뒀다(y=156·182).
        static let maxKeywordCount = 2

        static let panelHeight: CGFloat = 137
        static let panelHorizontalPadding: CGFloat = 18
        static let panelTopPadding: CGFloat = 18
        static let panelBottomPadding: CGFloat = 24

        static let profileSize: CGFloat = 24
        static let introductionIconSize: CGFloat = 18
        static let commaSize: CGFloat = 20
        static let quoteWidth: CGFloat = 204
        static let quoteHeight: CGFloat = 57
    }

    var body: some View {
        Button(action: onTapped) {
            ZStack(alignment: .topLeading) {
                backdrop
                cover
                information
                keywordChips
                bottomPanel
            }
            .frame(width: Metric.width, height: Metric.height)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius))
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Sections

private extension TodayDiscoveryCard {

    /// 표지를 카드 크기로 크게 깔아 흐리고, 그 위에 **반투명 그라데이션 에셋 `imgNovelBg`** 를 덮는다
    /// (구 WSSiOS `HomeTodayPopularCollectionViewCell`의 `backgroundNovelImageView` + `gradation` 그대로).
    ///
    /// ⚠️ **구 WSSiOS의 `imgTodayPopularBackground`를 가져오지 말 것**(V2엔 일부러 없다) — 이름이 이
    /// 화면 것처럼 보이지만 **알파 255의 불투명** 이미지라 표지를 통째로 가린다. 구 WSSiOS에서도 어디에도
    /// 안 쓰이는 잔재다. 여기 필요한 건 알파 217~255의 `imgNovelBg`다.
    /// ⚠️ 표지는 **상단 기준으로 자른다** — 세로가 길어 카드에 채우면 넘치는데, 기본 가운데 정렬이면
    /// 위아래가 같이 잘려 표지의 인상(제목·인물)이 사라진다(구 레포도 `alignment = .top`).
    var backdrop: some View {
        ZStack {
            WSSNovelCoverImage(url: discovery.novelThumbnailImage)
                .frame(width: Metric.width, height: Metric.height, alignment: .top)
                .clipped()
                // 구 레포는 `CIGaussianBlur`(radius 8) + `CIAffineClamp`를 원본 이미지에 구웠다 —
                // `opaque: true`가 그 clamp 역할(없으면 가장자리가 투명하게 번진다).
                .blur(radius: Metric.backdropBlurRadius, opaque: true)

            // 에셋 원본이 292×432(시안 노드와 동일)로 카드보다 길다. 구 레포도 `scaleToFill`로 프레임에
            // 맞췄고, 그라데이션이라 비율이 눌려도 티가 나지 않는다.
            WSSImage.imgNovelBg.swiftUIImage
                .resizable()
                .frame(width: Metric.width, height: Metric.height)
        }
    }

    var cover: some View {
        WSSNovelCoverImage(url: discovery.novelThumbnailImage)
            // 크기가 고정인 자리라 비율(`aspectRatio:`)이 아니라 프레임으로 잡는다. 넘친 그림은 아래 clip이 자른다.
            .frame(width: Metric.coverWidth, height: Metric.coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: Metric.coverCornerRadius))
            .shadow(color: Color.wssBlack.opacity(0.1), radius: 5.3, y: 1.4)
            .overlay(alignment: .bottomTrailing) { genreMark }
            .offset(x: Metric.coverLeading, y: Metric.coverTop)
    }

    /// 우하단 코너 라벨: **흰 코너 삼각형 배경(`icGenreBackground`) 위에 장르 아이콘(`iconImage`)** 을 얹는다.
    /// NovelDetail 표지 뱃지와 같은 구성이고(거긴 배경 71 / 아이콘 32 / 인셋 4·5), 여기선 시안 프레임이
    /// 56이라 **같은 비율로 축소**했다. ⚠️ 배경 없이 아이콘만 얹거나 `markImage`(GenreMark)를 쓰면 틀린다.
    var genreMark: some View {
        WSSImage.icGenreBackground.swiftUIImage
            .resizable()
            .frame(width: Metric.genreBackgroundSize, height: Metric.genreBackgroundSize)
            .overlay(alignment: .bottomTrailing) {
                discovery.novelGenre.iconImage
                    .resizable()
                    .frame(width: Metric.genreIconSize, height: Metric.genreIconSize)
                    .padding(.trailing, Metric.genreIconTrailingInset)
                    .padding(.bottom, Metric.genreIconBottomInset)
            }
    }

    var information: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(discovery.novelTitle)
                .applyWSSFont(.title2, color: .wssBlack, alignment: .leading)
                .lineLimit(2)

            Spacer().frame(height: 4)

            // ⚠️ 작가 이름에 **고정·최대 폭을 주지 말 것** — 이름이 짧아도 그 폭을 차지해
            // `· 연재작`이 저 멀리 떨어진다(시안의 작가 프레임 72는 샘플 이름이 길어 꽉 찼던 것뿐).
            // 연재상태를 `fixedSize` + 우선순위로 지키고, 남는 폭에서 이름만 말줄임되게 한다.
            HStack(spacing: 0) {
                Text(discovery.novelAuthor)
                    .applyWSSFont(.body3, color: .wssGray200, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(" · \(publicationStatusText)")
                    .applyWSSFont(.body3, color: .wssGray200, alignment: .leading)
                    .fixedSize()
                    .layoutPriority(1)
            }
        }
        .frame(width: Metric.infoWidth, alignment: .leading)
        .offset(x: Metric.infoLeading, y: Metric.infoTop)
    }

    @ViewBuilder
    var keywordChips: some View {
        // 키워드가 없는 작품이 실제로 온다 — 그땐 칩 영역이 통째로 없다.
        if !discovery.keywords.isEmpty {
            VStack(alignment: .leading, spacing: Metric.chipSpacing) {
                ForEach(discovery.keywords.prefix(Metric.maxKeywordCount), id: \.self) { keyword in
                    Text(keyword)
                        .applyWSSFont(.label2, color: .wssPrimary100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.wssPrimary20)
                        .clipShape(Capsule())
                }
            }
            // 키워드는 서버가 주는 자유 문자열이라 길이 보장이 없다 — 제한이 없으면 칩이
            // 옆(x=153)의 표지 위까지 자란다. 왼쪽 정보 컬럼과 같은 폭까지만 허용하고 넘치면 말줄임.
            // ⚠️ 이 상한은 **칩(Text)이 아니라 컨테이너에** 건다 — `maxWidth`는 상한이 아니라
            // "제안된 폭까지 늘어나라"라서, 칩에 직접 걸면 짧은 키워드도 120짜리 캡슐로 부푼다.
            // 컨테이너에 걸면 칩은 폭 제안만 받고 제 이상적 크기(=글자 폭)를 그대로 쓴다.
            .frame(maxWidth: Metric.infoWidth, alignment: .leading)
            .offset(x: Metric.infoLeading, y: Metric.chipTop)
        }
    }

    var bottomPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                sourceRow
                Spacer().frame(height: 16)
                quoteRow
            }
            .padding(.horizontal, Metric.panelHorizontalPadding)
            .padding(.top, Metric.panelTopPadding)
            .padding(.bottom, Metric.panelBottomPadding)
            .frame(width: Metric.width, height: Metric.panelHeight, alignment: .leading)
            .background(Color.wssWhite.opacity(0.7))
            .background(.ultraThinMaterial)
        }
    }

    /// 본문의 출처 — 유저 한마디면 그 유저의 프로필·닉네임, 작품 소개면 아이콘 + 고정 문구.
    @ViewBuilder
    var sourceRow: some View {
        switch discovery.content {
        case .userComment(let user):
            HStack(spacing: 10) {
                WSSAsyncImage(url: user.profileImage) { image in
                    image.resizable().scaledToFill()
                } placeholder: { _ in
                    Color.wssGray50
                }
                .frame(width: Metric.profileSize, height: Metric.profileSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(user.nickname)님의 한마디")
                    .applyWSSFont(.title2, color: .wssGray300, alignment: .leading)
                    .lineLimit(1)
            }

        case .novel:
            HStack(spacing: 8) {
                WSSImage.icIntroduction.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.introductionIconSize, height: Metric.introductionIconSize)

                Text("작품 소개")
                    .applyWSSFont(.title2, color: .wssGray300, alignment: .leading)
            }
        }
    }

    /// 여는 따옴표는 위, 닫는 따옴표는 아래에 붙는다(본문 높이 고정 57).
    var quoteRow: some View {
        HStack(alignment: .top, spacing: 6) {
            WSSImage.icCommasStarted.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Metric.commaSize, height: Metric.commaSize)

            Text(discovery.contentDescription)
                .applyWSSFont(.body4, color: .wssGray300, alignment: .leading)
                .lineLimit(3)
                .frame(width: Metric.quoteWidth, height: Metric.quoteHeight, alignment: .topLeading)

            VStack(spacing: 0) {
                Spacer()
                WSSImage.icCommasFinished.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.commaSize, height: Metric.commaSize)
            }
            .frame(height: Metric.quoteHeight)
        }
    }

    var publicationStatusText: String {
        switch discovery.publicationStatus {
        case .onGoing:   "연재작"
        case .completed: "완결작"
        }
    }
}
