//
//  FeedDetailAttachImageBlock.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

struct FeedDetailAttachImageBlock: View {

    let imageURLs: [URL?]
    var onImageTapped: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { geometry in
            let count = imageURLs.count

            switch count {
            case 1:
                WSSColor.wssGray100.swiftUIColor
                    .aspectRatio(1, contentMode: .fill)
                    .overlay {
                        imageView(url: imageURLs[0])
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .onTapGesture { onImageTapped(0) }

            case 2, 3:
                HStack(spacing: 7) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        WSSColor.wssGray100.swiftUIColor
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                imageView(url: url)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .onTapGesture { onImageTapped(index) }
                    }
                }
                .padding(.horizontal, 16)

            default:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in

                            WSSColor.wssGray100.swiftUIColor
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    imageView(url: url)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .onTapGesture { onImageTapped(index) }
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .contentMargins(.horizontal, 16)
            }
        }
        .frame(height: sectionHeight)
    }
    
    private var sectionHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        
        switch imageURLs.count {
        case 1:
            return screenWidth
            
        case 2:
            return (screenWidth - 7) / 2
            
        case 3:
            return (screenWidth - 14) / 3
            
        default:
            return 100
        }
    }
    
    private func imageView(url: URL?) -> some View {
        // 첨부 이미지는 셀 여러 장 + 확대 뷰가 같은 URL을 반복 렌더하므로 raw AsyncImage면 캐시 히트에도
        // placeholder가 번쩍인다 → WSSAsyncImage로 인메모리 캐시 공유. 원래 3-상태(로딩 중 ProgressView /
        // 실패 기본 썸네일 / 성공 이미지)를 isLoading으로 그대로 재현하고, 바깥에 있던 .scaledToFill()은
        // 각 뷰 안으로 옮긴다(ProgressView엔 원래도 영향 없음).
        WSSAsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: { isLoading in
            if isLoading {
                ProgressView()
            } else {
                WSSImage.imgLoadingThumbnail.swiftUIImage
                    .resizable()
                    .scaledToFill()
            }
        }
    }
}

#Preview {
        VStack(alignment: .center, spacing: 10) {
            FeedDetailAttachImageBlock(
                imageURLs: [
                    URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg")
                ]
            )
            
            
            FeedDetailAttachImageBlock(
                imageURLs: [
                    URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg"),
                    URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg")
                ]
            )
            
            
            FeedDetailAttachImageBlock(
                imageURLs: [
                    URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg"),
                    URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg"),
                    URL(string: "https://i.pinimg.com/736x/41/ad/4b/41ad4bc22cf862de46e376d265df9c91.jpg")
                ]
            )
            
            FeedDetailAttachImageBlock(
                imageURLs: [
                    URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg"),
                    URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg"),
                    URL(string: "https://i.pinimg.com/736x/41/ad/4b/41ad4bc22cf862de46e376d265df9c91.jpg"),
                    URL(string: "https://i.pinimg.com/736x/1e/9d/0d/1e9d0d13780c51b990002f1ae78f667f.jpg"),
                    URL(string: "https://i.pinimg.com/736x/0f/73/6f/0f736f80e9eb87e91b5229bc1c3d8550.jpg")
                ]
            )
        }
}
