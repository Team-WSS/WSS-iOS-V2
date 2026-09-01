//
//  WSSProfileImage.swift
//  WSSComponent
//
//  Created by Claude on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 유저 프로필 이미지 — 캐시(`WSSAsyncImage`) + 로딩 중 `ProgressView` + 기본 이미지 폴백을 묶은 편의 래퍼.
/// URL이 없거나 로딩이 실패하면 `defaultImage`(기본값 `imgEmptyCover`)로 대체하고, 캐시 미스로 실제
/// 네트워크 요청이 도는 동안만 `ProgressView`를 보여준다(`WSSAsyncImage`의 `isLoading` 인자, #237 후속 —
/// `WSSNovelCoverImage.PlaceholderStyle.default`와 동일한 로딩 표현).
///
/// 크기·모서리(원형/둥근 사각형)는 자리마다 달라 호출자가 바깥에서 `.frame`/`.clipShape`로 얹는다
/// (`WSSNovelCoverImage`의 "아무것도 안 넘기고 밖에서 프레임" 모드와 동일 계약 — 프로필 이미지는
/// 열 너비를 따라가야 하는 그리드 자리가 없어 `aspectRatio`/그리드 스타일은 두지 않았다).
public struct WSSProfileImage: View {

    private let url: URL?
    // ⚠️ 파라미터 타입은 `WSSImage`(= `DesignSystemAsset.Images`, static let들의 네임스페이스 enum)가
    // 아니라 그 static let들의 실제 값 타입인 `DesignSystemImages`다 — `WSSImage.imgEmptyCover` 같은
    // 표현식의 *타입*은 `DesignSystemImages`이지 `WSSImage` 자신이 아니다(네임스페이스 enum은 인스턴스가
    // 없다).
    private let defaultImage: DesignSystemImages
    /// 대부분의 프로필 자리(원형·둥근 사각형 아바타)는 `.fill`로 꽉 채워 자른다. 크롭 없이 원본 비율을
    /// 그대로 보여줘야 하는 자리(예: 캐릭터 선택 시트의 큰 대표 이미지)만 `.fit`을 넘긴다.
    private let contentMode: ContentMode

    public init(
        url: URL?,
        defaultImage: DesignSystemImages = WSSImage.imgEmptyCover,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.defaultImage = defaultImage
        self.contentMode = contentMode
    }

    public var body: some View {
        WSSAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: { isLoading in
            if isLoading {
                ProgressView()
            } else {
                defaultImage.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
    }
}
