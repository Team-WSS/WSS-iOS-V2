//
//  WSSFeedDemoView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import WSSComponent

struct WSSFeedDemoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 이미지 + 연결 작품 모두 있는 경우
                SectionHeader("이미지 + 연결 작품")
                WSSFeadView(
                    header: FeedHeader(
                        profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                        nickname: "구리스",
                        createdDate: "2024년 6월 19일",
                        isEdited: true
                    ),
                    profileImageTapped: { print("프로필 이미지 탭!") },
                    threeDotsButtonTapped: { print("드롭다운 버튼 탭!") },
                    content: "대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고 설정을 짠게 느껴져서 좋아요. 대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고 설정을 짠게 느껴져서 좋아요. 대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고 설정을 짠게 느껴져서 좋아요.",
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
                        commentCount: 23
                    )
                )
                
                Divider()

                // 이미지만 있는 경우
                SectionHeader("이미지만 있음")
                WSSFeadView(
                    header: FeedHeader(
                        profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                        nickname: "독서왕",
                        createdDate: "2024년 7월 3일",
                        isEdited: false
                    ),
                    profileImageTapped: { print("프로필 이미지 탭!") },
                    threeDotsButtonTapped: { print("드롭다운 버튼 탭!") },
                    content: "오늘 읽은 책의 한 장면이 너무 인상적이었어요. 사진으로 남겨봅니다.",
                    feedImage: WSSFeedImage(
                        thumbnailImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                        imageCount: 1
                    ),
                    react: WSSFeedReact(
                        likeCount: 7,
                        commentCount: 2
                    )
                )
                
                Divider()

                // 연결 작품만 있는 경우
                SectionHeader("연결 작품만 있음")
                WSSFeadView(
                    header: FeedHeader(
                        profileImageURL: nil,
                        nickname: "로판덕후",
                        createdDate: "2024년 8월 15일",
                        isEdited: false
                    ),
                    profileImageTapped: { print("프로필 이미지 탭!") },
                    threeDotsButtonTapped: { print("드롭다운 버튼 탭!") },
                    content: "이 작품 진짜 강추합니다!! 요즘 로판 중에 제일 재밌어요. 여주가 너무 멋있고 스토리 전개도 빠르고 좋아요.",
                    linkNovel: WSSLinkNovel(
                        genreType: .romanceFantasy,
                        novelTitle: "공주는 아무나 하나요",
                        novelRating: 4.2
                    ),
                    react: WSSFeedReact(
                        likeCount: 42,
                        commentCount: 15
                    )
                )
                
                Divider()

                // 이미지, 연결 작품 모두 없는 경우
                SectionHeader("텍스트만")
                WSSFeadView(
                    header: FeedHeader(
                        profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                        nickname: "웹소소",
                        createdDate: "2024년 9월 1일",
                        isEdited: true
                    ),
                    profileImageTapped: { print("프로필 이미지 탭!") },
                    threeDotsButtonTapped: { print("드롭다운 버튼 탭!") },
                    content: "요즘 읽을 소설 추천 받습니다! 판타지나 무협 장르 좋아하는데 뭐 괜찮은 거 있을까요?",
                    react: WSSFeedReact(
                        likeCount: 3,
                        commentCount: 8
                    )
                )
            }
            .padding(.vertical, 20)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 20)
            Spacer()
        }
    }
}
