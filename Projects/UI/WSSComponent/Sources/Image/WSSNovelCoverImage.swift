//
//  WSSNovelCoverImage.swift
//  WSSComponent
//
//  Created by YunhakLee on 7/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 소설 표지 이미지 — 캐시(`WSSAsyncImage`) + 표지 표준 렌더(`scaledToFill`) + WSS 빈 표지 폴백을 묶은 편의 래퍼.
/// URL이 없거나 로딩이 실패하면 WSS 빈 표지(`imgLoadingThumbnail`)로 대체한다(정본: NovelDetail 헤더).
/// **로딩 중(캐시 미스로 실제 네트워크 요청이 도는 동안)엔 `placeholderStyle`에 따라 `ProgressView`를 보여준다**
/// — 아래 `PlaceholderStyle` 참고.
///
/// 크기는 두 가지 방식 중 하나로 정한다:
/// - **`aspectRatio`를 넘긴다** — 폭은 부모가 준 만큼 쓰고 높이는 비율로 정해진다(그리드 셀처럼 열 너비를
///   따라가야 할 때). 넘친 그림은 컴포넌트가 잘라낸다.
/// - **아무것도 안 넘기고 밖에서 `.frame(width:height:)`** — 크기가 고정인 자리(추천글 행 썸네일 등).
///
/// ⚠️ **밖에서 `.aspectRatio`를 직접 걸지 말 것** — 표지는 `scaledToFill`(= `aspectRatio(.fill)`)이라
/// 둘이 충돌해 표지가 좁아진다. 그래서 비율을 **파라미터로 받는다**.
///
/// 모서리 클립(`clipShape`)·오버레이(뱃지·하트)는 자리마다 달라 호출자가 바깥에서 얹는다.
public struct WSSNovelCoverImage: View {

    /// 로딩 중(캐시 미스) 표시 방식. **호출부가 명시적으로 고른다** — `aspectRatio` 유무로 추론하지
    /// 않는다(크기 결정 방식과 로딩 표시 방식은 서로 다른 축이라, 섞으면 나중에 그리드가 아닌데
    /// `aspectRatio`만 쓰는 자리가 생겼을 때 조용히 잘못된 스타일을 물려받는다).
    public enum PlaceholderStyle {
        /// 로딩 중엔 배경 없이 `ProgressView`만, 그 외(URL nil·실패)엔 기본 표지. 한 화면에 이
        /// 컴포넌트가 하나(또는 소수)만 보이는 자리 — 작품 검색 결과 행, 서재 리스트 셀 등.
        case `default`
        /// 로딩 중엔 `wssGray50` 배경 위에 `ProgressView`, 그 외엔 기본 표지. **`LazyVGrid`처럼 여러
        /// 셀이 한 화면에 동시에 뜨는 자리 전용** — 셀마다 스피너가 따로 도는 대신 조용한 배경으로
        /// 채워, 그리드 전체가 한꺼번에 로딩 중일 때 스피너가 여러 개 겹쳐 산만해지는 걸 피한다.
        case grid
    }

    private let url: URL?
    private let aspectRatio: CGFloat?
    private let placeholderStyle: PlaceholderStyle
    /// 표지 표준은 `.fill`(꽉 채워 자름)이라 기본값이다. `aspectRatio` 모드는 내부적으로 `.fill`
    /// 전제로 크기를 계산하므로(비율 상자에 overlay로 채움), `.fit`은 **`aspectRatio`를 안 쓰는
    /// 자리에서만** 의미 있게 동작한다 — 원본을 자르지 않고 보여줘야 하는 예외적인 자리(연결 작품
    /// 배너 등)에 한해 명시로 넘길 것.
    private let contentMode: ContentMode

    public init(
        url: URL?,
        aspectRatio: CGFloat? = nil,
        placeholderStyle: PlaceholderStyle = .default,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.placeholderStyle = placeholderStyle
        self.contentMode = contentMode
    }

    public var body: some View {
        if let aspectRatio {
            // 비율은 **투명 뷰가 잡고 그림은 overlay로 채운다** — 표지 자신에게 비율을 걸면
            // `scaledToFill`과 충돌하므로, 크기를 정하는 역할과 채우는 역할을 분리한다.
            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay { coverImage }
                // 채우다 넘친 그림이 이웃 셀 위로 삐져나오지 않게 프레임에서 자른다.
                // (그리기만 자르므로 탭 영역이 필요하면 호출부가 `.contentShape`를 얹는다.)
                .clipped()
        } else {
            coverImage
        }
    }

    private var coverImage: some View {
        WSSAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: { isLoading in
            placeholderView(isLoading: isLoading)
        }
    }

    @ViewBuilder
    private func placeholderView(isLoading: Bool) -> some View {
        switch placeholderStyle {
        case .default:
            if isLoading {
                ProgressView()
            } else {
                defaultCover
            }
        case .grid:
            if isLoading {
                Color.wssGray50
                    .overlay { ProgressView() }
            } else {
                defaultCover
            }
        }
    }

    private var defaultCover: some View {
        WSSImage.imgLoadingThumbnail.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
}
