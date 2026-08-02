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
/// 프레임·모서리 클립·오버레이(뱃지·하트)는 호출자가 바깥에서 얹는다 — 표지 자체는 `scaledToFill`만.
public struct WSSNovelCoverImage: View {

    private let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
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
