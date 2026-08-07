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
/// 이미지가 없거나(URL nil)·로딩·실패면 WSS 빈 표지(`imgLoadingThumbnail`)로 대체한다(정본: NovelDetail 헤더).
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

    private let url: URL?
    private let aspectRatio: CGFloat?

    public init(url: URL?, aspectRatio: CGFloat? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
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
                .scaledToFill()
        } placeholder: {
            WSSImage.imgLoadingThumbnail.swiftUIImage
                .resizable()
                .scaledToFill()
        }
    }
}
