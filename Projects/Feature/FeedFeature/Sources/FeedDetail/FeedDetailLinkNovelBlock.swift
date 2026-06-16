//
//  FeedDetailLinkNovelBlock.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem

struct FeedDetailLinkNovelBlock: View {
    
    let imageURL: URL?
    let title: String
    let novelDescription: String
    let genre: NovelGenre
    let feedWriteUsername: String
    let feedWriteUserRating: Float
    let totalRating: Float
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: imageURL) { phase in
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
                .frame(width: 86)
                .scaledToFit()
                
                genre.markImage
                    .resizable()
                    .frame(width: 50, height: 50)
                    .scaledToFit()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // 제목
                Text(title)
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: 2)
                
                // 별점
                HStack(spacing: 8) {
                    // 피드 작성자 별점
                    if feedWriteUserRating > 0 {
                        HStack(spacing: 2) {
                            Text(feedWriteUsername)
                                .applyWSSFont(.body5)
                                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                            
                            WSSImage.icSmallStarEmpty.swiftUIImage
                                .renderingMode(.template)
                                .foregroundStyle(WSSColor.wssSecondary100.swiftUIColor)
                                .frame(width: 12, height: 12)
                            
                            Text(String(feedWriteUserRating))
                                .applyWSSFont(.body5)
                                .foregroundStyle(WSSColor.wssSecondary100.swiftUIColor)
                        }
                    }

                    // 전체 별점
                    HStack(spacing: 2) {
                        Text("전체")
                            .applyWSSFont(.body5)
                            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                        
                        WSSImage.icSmallStarEmpty.swiftUIImage
                            .renderingMode(.template)
                            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                            .frame(width: 12, height: 12)
                        
                        Text(String(totalRating))
                            .applyWSSFont(.body5)
                            .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    }
                }
                
                Spacer().frame(height: 8)
                
                // 작품 설명
                Text(novelDescription)
                    .applyWSSFont(.body5)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 7)
            
            Spacer()
        }
        .frame(height: 123)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(WSSColor.wssGray80.swiftUIColor, lineWidth: 1)
        }
        
    }
}

#Preview {
    FeedDetailLinkNovelBlock(
        imageURL: URL(string: "https://i.pinimg.com/736x/fe/61/a3/fe61a3449cb9c20f9c304ad2d95edfd7.jpg"),
        title: "짐승 대공의 부인이 되었습니다",
        novelDescription: "꼰대 사수에게 석 달간 볶여 가며 끝낸 프로젝트에서 거나하게 성과급을 받았는데, 써 보지도 못하고 죽어버렸다. 그것만 해도 어이가 없는데, 눈 떠보니 죽기 전에 읽었던 <괴물 대공님의 부인>에서 남주에게 집착하다 끔살 당한 전처가",
        genre: .modernFantasy,
        feedWriteUsername: "이마세",
        feedWriteUserRating: 3.0,
        totalRating: 4.32
    )
}
