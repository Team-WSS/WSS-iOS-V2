//
//  CreateFeedConnectNovelRow.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

struct CreateFeedConnectNovelRow: View {
    let imageURL: URL?
    let title: String
    let author: String
    
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            AsyncImage(url: imageURL) {
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
            .frame(width: 78, height: 105)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer().frame(width: 18)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .applyWSSFont(.title3)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .lineLimit(1)
                
                Text(author)
                    .applyWSSFont(.body5)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            (isSelected
             ? WSSImage.icSelectNovelSelected.swiftUIImage
             : WSSImage.icSelectNovelDefault.swiftUIImage)
            .frame(width: 44, height: 44)
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.5),
                value: isSelected
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    CreateFeedConnectNovelRow(
        imageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
        title: "여주인공의 이해를 돕기 위하여",
        author: "이보라",
        isSelected: true,
        action: { print("전체 클릭") }
    )
}
