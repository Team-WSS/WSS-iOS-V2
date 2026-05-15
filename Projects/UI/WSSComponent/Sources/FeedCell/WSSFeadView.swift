//
//  WSSFeadView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

public struct WSSFeadView: View {
    
    // 피드 헤더
    let header: FeedHeader

    // 피드 내용
    let content: String
    
    // 첨부 이미지
    let feedImage: WSSFeedImage?
    
    // 연결 작품
    let linkNovel: WSSLinkNovel?

    // 피드 리액션
    let react: WSSFeedReact
    
    public init(
        header: FeedHeader,
        content: String,
        feedImage: WSSFeedImage? = nil,
        linkNovel: WSSLinkNovel? = nil,
        react: WSSFeedReact
    ) {
        self.header = header
        self.content = content
        self.feedImage = feedImage
        self.linkNovel = linkNovel
        self.react = react
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // 피드 헤더
            WSSFeadHeaderView(header: header)
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 10)
            
            // 피드 글
            HStack(spacing: 0) {
                Text(content)
                    .applyWSSFont(.body2)
                    .foregroundStyle(Color.wssBlack)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // 피드 첨부 이미지
            if let feedImage {
                WSSFeedImageView(feedImage: feedImage)
                    .padding(.horizontal, 12.5)
                
                Spacer().frame(height: 10)
            }

            // 피드 연결 작품
            if let linkNovel {
                WSSLinkNovelView(
                    genreType: linkNovel.genreType,
                    novelTitle: linkNovel.novelTitle,
                    novelRating: linkNovel.novelRating
                )
                .padding(.horizontal, 16)

                Spacer().frame(height: 10)
            }
            
            // 피드 리액션
            WSSFeedReactView(react: react)
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

#Preview {
    WSSFeadView(
        header: FeedHeader(
            profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
            nickname: "구리스",
            createdDate: "2024년 6월 19일",
            isEdited: true,
            profileImageTapped: { print("프로필 클릭!") },
            threeDotsButtonTapped: { print("드롭다운 클릭!") }
        ),
        content: "대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고 설정을 짠게 느껴져서 좋아요. 요즘 하도 라이트하고 가짜 마법물이 많아서 ㅠ 찐 성장+마법물!! 글고 일단 작가님 필력이 무난하게 잘뽑으시고 연재도 빠르니까 너무너무 좋다!! 요즘 하도 라이트하고 가짜 마법물이 많아서 ㅠ 찐 ",
        feedImage: WSSFeedImage(
            thumbnailImageURL: URL(string: "https://i.pinimg.com/736x/66/0a/11/660a1122583033a20cf90ce9dccbe2c2.jpg"),
            imageCount: 5
        ),
        linkNovel: WSSLinkNovel(
            genreType: .modernFantasy,
            novelTitle: "스즈미야 하루히의 무료",
            novelRating: 4.3
        ),
        react: WSSFeedReact(
            likeCount: 13,
            commentCount: 23,
            likeButtonTapped: { print("좋아요 클릭!") }
        )
    )
}
