//
//  WSSFeedImageView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

//MARK: - Feed Image 구조체

public struct WSSFeedImage {
    let thumbnailImageURL: URL?
    let imageCount: Int
    
    public init(
        thumbnailImageURL: URL?,
        imageCount: Int
    ) {
        self.thumbnailImageURL = thumbnailImageURL
        self.imageCount = imageCount
    }
}

//MARK: - Feed Image 뷰

public struct WSSFeedImageView: View {
    
    let feedImage: WSSFeedImage
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: feedImage.thumbnailImageURL) {
                phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                case .failure:
                    WSSImage.imgLoadingThumbnail.swiftUIImage
                        .resizable()
                default:
                    ProgressView()
                }
            }
            .scaledToFill()
            .frame(height: 248)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            Text(String(feedImage.imageCount))
                .applyWSSFont(.body5)
                .foregroundStyle(Color.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.wssGrayToast)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.bottom, 10)
                .padding(.trailing, 12)
        }
        // scaledToFill로 프레임 밖까지 커진 이미지는 clipShape가 그리기만 자르고 hit-test
        // 영역은 그대로 남긴다 — 정사각형보다 세로로 긴 이미지면 보이지 않는 터치 영역이
        // 위 헤더(프로필·threedots)까지 덮어 탭을 가로챈다. 이미지는 장식 요소이므로
        // 터치를 통과시킨다(이미지 탭 = 셀 탭 폴스루, 기존 의도와 동일).
        .allowsHitTesting(false)
    }
}

#Preview {
    WSSFeedImageView(feedImage:
                        WSSFeedImage(
                            thumbnailImageURL: URL(string: "https:"),
                            imageCount: 5
                        )
    )
}
