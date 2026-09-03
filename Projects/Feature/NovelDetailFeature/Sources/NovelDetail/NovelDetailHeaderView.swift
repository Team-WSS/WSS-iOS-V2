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
    /// ScrollView 좌표공간 이름 — 상단 오버스크롤(당겨서 내림)을 재 backdrop을 stretch시키는 데 쓴다.
    let scrollSpaceName: String
    /// 표지 탭 콜백 — 대형 표지 오버레이 표시 여부는 화면(NovelDetailView)이 소유한다.
    let onCoverTapped: () -> Void
    /// 작가 이름 탭 콜백 — 전달값은 탭한 작가 한 명의 이름. 실제 화면 전환은 화면(NovelDetailView)을 거쳐 호출자가 수행한다.
    let onAuthorTapped: (String) -> Void

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
    /// → 아래 회색(wssGray50) 영역으로 자연 연결. 커버·backdrop 모두 `WSSNovelCoverImage`라 표지가
    /// 없거나 로딩 중이면 컴포넌트 폴백(기본 표지/스피너)이 뜨지만, 그라데이션(상단 85%)에 가려 상단에서만 은은히 비친다.
    /// ⚠️ 그라데이션 에셋의 알파는 85%(상단)~100%(하단) — 블러 표지는 상단에서만 은은히 비친다.
    /// - 블러를 radius 12→6→3으로 완화해 표지 아트가 상단에서 더 또렷이 비치게 했다(#221·#244 사용자 피드백).
    ///   보라 그라데이션은 디자인대로 **full opacity로 커버 위에 그대로** 얹는다(opacity를 낮춰 보라가
    ///   옅어지면 안 된다 — 사용자 지적). 제목은 backdropHeight 아래(gray50) 위라 가독성엔 영향 없다.
    /// - 상단 오버스크롤(당겨서 내림) 시 blur 레이어를 그만큼 확대해 빈 영역을 메우는 순수 SwiftUI
    ///   stretch. 예전엔 `TopBounceDisabler`(contentOffset KVO)로 상단 바운스를 막았으나, #200 컬렉션
    ///   상세처럼 stretch로 교체해 KVO를 없앴다(#221 → Swift 6 mode 6 승격). anchor .top + offset(-stretch)로
    ///   확대해도 하단 경계(gray50 접점)는 고정되고 위쪽으로만 번진다(`CollectionDetailView.heroSection`과 동일 계산).
    private var backdrop: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let minY = proxy.frame(in: .named(scrollSpaceName)).minY
                let stretch = max(0, minY)
                let zoomScale = 1 + stretch / backdropHeight

                ZStack {
                    // 전경 표지와 같은 WSSNovelCoverImage → 같은 URL을 인메모리 캐시로 공유(중복 다운로드
                    // 없음, 재진입 시 배경도 번쩍임 없음). fill이 프레임 밖으로 넘치므로 .clipped()로 자른다.
                    WSSNovelCoverImage(url: novel.thumbnailImage)
                        .frame(width: proxy.size.width, height: backdropHeight, alignment: .top)
                        .clipped()
                        .blur(radius: 3, opaque: true)

                    WSSImage.imgDetailBackgroundGradation.swiftUIImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: backdropHeight)
                        .clipped()
                }
                .frame(width: proxy.size.width, height: backdropHeight)
                .clipped()
                .scaleEffect(zoomScale, anchor: .top)
                .offset(y: -stretch)
            }
            .frame(height: backdropHeight)

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
            // 크기가 고정(148×217)인 자리라 aspectRatio 없이 밖에서 .frame으로 크기를 준다.
            // URL nil·로딩 실패 시 컴포넌트가 기본 표지(imgLoadingThumbnail)로 폴백한다(기존 else 분기와 동일).
            WSSNovelCoverImage(url: novel.thumbnailImage)
                .frame(width: 148, height: coverHeight)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.wssBlack.opacity(0.1), radius: 15, x: 0, y: 2)
                // 장르 마크는 표지 우하단 모서리에 정렬(디자인 좌표: 표지 bottom/trailing 일치)
                .overlay(alignment: .bottomTrailing) {
                    if let genre = information.novel.genres.first {
                        genreMark(genre)
                    }
                }
                // clipShape는 그리기만 자르므로 탭 영역은 .contentShape로 명시(표지 fill이 위아래로 넘침)
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
            metaRow
            Spacer().frame(height: 6)
            countsRow
        }
    }

    /// "로판/로맨스  ·  완결작  ·  이보라, 김작가" — 장르 나열 / 연재 상태 / 작가.
    /// 작가만 개별 밑줄 버튼(탭 → 작가 검색)이라 세 값을 단일 `Text`로 합치지 못하고 HStack으로 분해한다.
    /// 앞부분(장르·연재상태)은 한 `Text`, 작가는 이름마다 `Button`, 구분자(`  ·  `/`, `)는 탭 대상이 아닌 텍스트.
    private var metaRow: some View {
        HStack(spacing: 0) {
            Text(nonAuthorMetaText)
                .applyWSSFont(.body3)
                .foregroundStyle(Color.wssGray200)
            if !novel.authors.isEmpty {
                Text("  ·  ")
                    .applyWSSFont(.body3)
                    .foregroundStyle(Color.wssGray200)
                ForEach(Array(novel.authors.enumerated()), id: \.offset) { index, author in
                    if index > 0 {
                        Text(", ")
                            .applyWSSFont(.body3)
                            .foregroundStyle(Color.wssGray200)
                    }
                    Button {
                        onAuthorTapped(author)
                    } label: {
                        // ⚠️ `.underline()`은 raw `Text`에 먼저 걸어야 한다(Text.underline() → Text).
                        // `applyWSSFont`/`foregroundStyle`이 반환하는 `some View` 단계에 걸면 밑줄이 글리프에
                        // baked-in 되지 않아 컴파일은 되지만 조용히 렌더되지 않는다.
                        Text(author)
                            .underline()
                            .applyWSSFont(.body3)
                            .foregroundStyle(Color.wssGray200)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// 작가를 뺀 앞부분 = 장르 나열 / 연재 상태. 연재 상태는 항상 포함이라 절대 비지 않는다
    /// → `metaRow`가 작가 앞 `  ·  ` 구분자를 안전하게 붙일 수 있다.
    private var nonAuthorMetaText: String {
        var parts: [String] = []
        if !information.novel.genres.isEmpty {
            parts.append(information.novel.genres.map(\.displayName).joined(separator: "/"))
        }
        parts.append(publicationStatusName)
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
