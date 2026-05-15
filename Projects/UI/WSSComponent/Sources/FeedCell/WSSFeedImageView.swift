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
    }
}

#Preview {
    WSSFeedImageView(feedImage:
                        WSSFeedImage(
                            thumbnailImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                            imageCount: 5
                        )
    )
}
