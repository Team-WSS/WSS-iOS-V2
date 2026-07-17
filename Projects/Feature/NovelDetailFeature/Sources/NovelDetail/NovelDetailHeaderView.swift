//
//  NovelDetailHeaderView.swift
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

/// 몰입형 헤더: 블러 커버 배경 + 표지(장르 마크) + 제목·메타·카운트.
/// `novel`은 관심 토글이 반영되는 값이라 `information.novel` 대신 따로 받는다.
struct NovelDetailHeaderView: View {

    let information: NovelInformation
    let novel: Novel
    /// 커스텀 네비바 하단 y(= 안전영역 top + 네비바 높이). 표지는 네비바 바로 아래에서 시작한다.
    /// 디자인의 99는 특정 기기(상태바 54 + 네비 44) 값이라 안전영역이 다른 기기에서 어긋난다 → 실측값을 받는다.
    let topInset: CGFloat
    /// 표지 탭 콜백 — 대형 표지 오버레이 표시 여부는 화면(NovelDetailView)이 소유한다.
    let onCoverTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: topInset)
            coverImage
            Spacer().frame(height: 20)
            titleBlock
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { backdrop }
    }

    // MARK: - Backdrop

    /// 커버를 크게 깔아 블러하고 그 위에 디자인의 radial gradient 에셋(#D2D3F8→#F4F5F8)을 덮는다
    /// → 아래 회색(wssGray50) 영역으로 자연 연결.
    /// ⚠️ 그라데이션 에셋의 알파는 85%(상단)~100%(하단) — 블러 표지는 상단에서만 은은히 비치고,
    /// 표지가 없으면 그라데이션만 보인다. 그래서 블러 뒤에 깔 바탕색은 필요 없다.
    private var backdrop: some View {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(url: novel.thumbnailImage) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: backdropHeight, alignment: .top)
                .clipped()
                .blur(radius: 12, opaque: true)

                WSSImage.imgDetailBackgroundGradation.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: backdropHeight)
                    .clipped()
            }
            .frame(height: backdropHeight)
            .clipped()

            Color.wssGray50
        }
    }

    /// 회색 영역으로 넘어가는 지점 = 표지 아래 14pt (디자인 330 = 커버 top 99 + 표지 217 + 14).
    /// 표지가 `topInset`을 따라 움직이므로 배경도 같이 묶어야 제목이 회색 위에 놓인다(고정 330이면
    /// 안전영역이 작은 기기에서 제목이 블러 배경 위로 올라온다).
    private var backdropHeight: CGFloat {
        topInset + coverHeight + 14
    }

    // MARK: - Cover

    private var coverHeight: CGFloat { 217 }

    private var coverImage: some View {
        Button {
            onCoverTapped()
        } label: {
            AsyncImage(url: novel.thumbnailImage) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    WSSImage.imgLoadingThumbnail.swiftUIImage
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 148, height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.wssBlack.opacity(0.1), radius: 15, x: 0, y: 2)
            // 장르 마크는 표지 우하단 모서리에 정렬(디자인 좌표: 표지 bottom/trailing 일치)
            .overlay(alignment: .bottomTrailing) {
                if let genre = information.novel.genres.first {
                    genreMark(genre)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 우하단 코너 라벨: 흰 코너 삼각형 배경(icGenreBackground, 71pt)의 우하단에
    /// 장르 아이콘(iconImage, 32pt)을 trailing 4 / bottom 5 인셋으로 얹는다. (V1 레이아웃 그대로)
    private func genreMark(_ genre: NovelGenre) -> some View {
        WSSImage.icGenreBackground.swiftUIImage
            .resizable()
            .frame(width: 71, height: 71)
            .overlay(alignment: .bottomTrailing) {
                genre.iconImage
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(.trailing, 4)
                    .padding(.bottom, 5)
            }
    }

    // MARK: - Title / Meta / Counts

    private var titleBlock: some View {
        VStack(spacing: 0) {
            Text(novel.title)
                .applyWSSFont(.headline1)
                .foregroundStyle(Color.wssBlack)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
            Spacer().frame(height: 6)
            Text(metaText)
                .applyWSSFont(.body3)
                .foregroundStyle(Color.wssGray200)
            Spacer().frame(height: 6)
            countsRow
        }
    }

    /// "로판/로맨스  ·  완결작  ·  이보라" — 장르 나열 / 연재 상태 / 작가.
    private var metaText: String {
        var parts: [String] = []
        if !information.novel.genres.isEmpty {
            parts.append(information.novel.genres.map(\.displayName).joined(separator: "/"))
        }
        parts.append(publicationStatusName)
        if !novel.authors.isEmpty {
            parts.append(novel.authors.joined(separator: ", "))
        }
        return parts.joined(separator: "  ·  ")
    }

    /// NovelPublicationStatus는 NovelDomain 타입이라 WSSComponent(DomainPresentation)에 못 두고 여기서 매핑한다.
    private var publicationStatusName: String {
        switch information.publicationStatus {
        case .onGoing:   "연재작"
        case .completed: "완결작"
        }
    }

    private var countsRow: some View {
        HStack(spacing: 0) {
            countItem(icon: WSSImage.icCountInterest.swiftUIImage, text: "\(novel.interestCount)")
            Spacer().frame(width: 20)
            countItem(icon: WSSImage.icCountRating.swiftUIImage,
                      text: String(format: "%.1f (%d)", novel.rating, novel.ratingCount))
            Spacer().frame(width: 20)
            countItem(icon: WSSImage.icCountFeed.swiftUIImage, text: "\(information.feedCount)")
        }
    }

    private func countItem(icon: Image, text: String) -> some View {
        HStack(spacing: 0) {
            icon
                .resizable()
                .frame(width: 14, height: 14)
            Spacer().frame(width: 5)
            Text(text)
                .applyWSSFont(.body5_2)
                .foregroundStyle(Color.wssGray300)
        }
    }
}
