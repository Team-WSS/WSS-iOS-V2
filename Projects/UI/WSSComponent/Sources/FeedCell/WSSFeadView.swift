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
    
    let profileImageTapped: () -> Void
    /// 내 글이면 `false` — 내 프로필 탭 영역을 비활성화한다(`WSSFeadHeaderView` 참고).
    let isProfileTappable: Bool
    let threeDotsButtonTapped: () -> Void

    // 피드 내용
    let content: String
    
    // 첨부 이미지
    let feedImage: WSSFeedImage?
    
    // 연결 작품
    let linkNovel: WSSLinkNovel?

    // 피드 리액션
    let react: WSSFeedReact
    let isLiked: Bool
    let likeButtonTapped: () -> Void

    let isSpoiler: Bool
    /// 내 글이면 `true` — 스포일러 글이어도 본문·이미지를 가리지 않고, 리액션 줄 오른쪽에 작은
    /// "스포일러가 포함된 글" 표시만 붙인다. `false`(남의 글)면 본문 대신 "스포일러가 포함된 글 보기"로 가린다.
    let revealsSpoiler: Bool
    let isPrivate: Bool

    /// 스포일러 본문을 가려야 하는가 — 남의 스포일러 글일 때만.
    private var hidesSpoilerContent: Bool { isSpoiler && !revealsSpoiler }
    /// 리액션 줄 오른쪽 작은 스포일러 표시 — 내 스포일러 글일 때만.
    private var showsSpoilerBadge: Bool { isSpoiler && revealsSpoiler }

    public init(
        header: FeedHeader,
        profileImageTapped: @escaping () -> Void,
        isProfileTappable: Bool = true,
        threeDotsButtonTapped: @escaping () -> Void,
        content: String,
        feedImage: WSSFeedImage? = nil,
        linkNovel: WSSLinkNovel? = nil,
        react: WSSFeedReact,
        isLiked: Bool,
        likeButtonTapped: @escaping () -> Void,
        isSpoiler: Bool,
        revealsSpoiler: Bool = false,
        isPrivate: Bool
    ) {
        self.header = header
        self.profileImageTapped = profileImageTapped
        self.isProfileTappable = isProfileTappable
        self.threeDotsButtonTapped = threeDotsButtonTapped
        self.content = content
        self.feedImage = feedImage
        self.linkNovel = linkNovel
        self.react = react
        self.isLiked = isLiked
        self.likeButtonTapped = likeButtonTapped
        self.isSpoiler = isSpoiler
        self.revealsSpoiler = revealsSpoiler
        self.isPrivate = isPrivate
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // 피드 헤더
            WSSFeadHeaderView(
                header: header,
                profileImageTapped: profileImageTapped,
                isProfileTappable: isProfileTappable,
                threeDotsButtonTapped: threeDotsButtonTapped
            )
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 10)
            
            // 피드 글
            HStack(spacing: 0) {
                if hidesSpoilerContent {
                     Text("스포일러가 포함된 글 보기")
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssSecondary100)
                } else {
                    Text(content)
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssBlack)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 20)
            
            // 피드 첨부 이미지
            if let feedImage, !hidesSpoilerContent {
                WSSFeedImageView(feedImage: feedImage)
                    .padding(.horizontal, 12.5)
                
                Spacer().frame(height: 10)
            }

            // 피드 연결 작품
            if let linkNovel {
                WSSLinkNovelView(
                    genreType: linkNovel.genreType,
                    novelTitle: linkNovel.novelTitle,
                    novelRating: linkNovel.novelRating,
                    linkNovelTapped: linkNovel.linkNovelTapped
                )
                .padding(.horizontal, 16)

                Spacer().frame(height: 10)
            }
            
            // 피드 리액션 (+ 내 스포일러 글이면 오른쪽 끝에 작은 표시)
            // 두 리액션 뷰 모두 끝에 Spacer가 있어 표시가 오른쪽 끝으로 밀린다.
            HStack(spacing: 0) {
                if isPrivate {
                    privateSection
                } else {
                    WSSFeedReactView(
                        react: react,
                        isLiked: isLiked,
                        likeButtonTapped: likeButtonTapped
                    )
                }

                if showsSpoilerBadge {
                    Text("스포일러가 포함된 글")
                        .applyWSSFont(.label1)
                        .foregroundStyle(Color.wssSecondary100)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var privateSection: some View {
        HStack(spacing: 6) {
            WSSImage.icLock.swiftUIImage
                .renderingMode(.template)
            
            Text("나만 보는 기록이에요.")
                .applyWSSFont(.body4)
            
            Spacer()
        }
        .foregroundStyle(Color.wssGray200)
        .padding(.vertical, 10)
    }
}

#Preview {
    ScrollView {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: URL(string: "https://i.pinimg.com/736x/fd/fc/ef/fdfcefdd9bc7d69e9adf1dde8293fe6e.jpg"),
                nickname: "구리스",
                createdDate: "2024년 6월 19일",
                isEdited: true
            ),
            profileImageTapped: { print("프로필 이미지 탭!") },
            threeDotsButtonTapped: { print("드롭다운 버튼 탭!") },
            content: "대학원생이 환생에서 대학원생이 됨. 주인공 완전 갓갓! 일단 작가가 세계관이나 마법에 대해서 진지하게 생각해보고 설정을 짠게 느껴져서 좋아요. 요즘 하도 라이트하고 가짜 마법물이 많아서 ㅠ 찐 성장+마법물!! 글고 일단 작가님 필력이 무난하게 잘뽑으시고 연재도 빠르니까 너무너무 좋다!! 요즘 하도 라이트하고 가짜 마법물이 많아서 ㅠ 찐 ",
            feedImage: WSSFeedImage(
                thumbnailImageURL: URL(string: "https://i.pinimg.com/736x/66/0a/11/660a1122583033a20cf90ce9dccbe2c2.jpg"),
                imageCount: 5
            ),
            linkNovel: WSSLinkNovel(
                genreType: .modernFantasy,
                novelTitle: "스즈미야 하루히의 무료",
                novelRating: 4.3,
                linkNovelTapped: { print("연결 작품 탭!") }
            ),
            react: WSSFeedReact(
                likeCount: 13,
                commentCount: 23
            ),
            isLiked: true,
            likeButtonTapped: { print("좋아요 클릭!") },
            isSpoiler: true,
            isPrivate: true
        )
    }
}
