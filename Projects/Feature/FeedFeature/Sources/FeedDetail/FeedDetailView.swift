//
//  FeedDetailView.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import CommentDomain
import SocialDomain
import WSSComponent
import DesignSystem

struct FeedDetailView: View {

    @State private var viewModel: FeedDetailViewModel
    
    @State private var showFeedDropdown: Bool = false
    @State private var showCommentDropdown: Bool = false

    init(viewModel: FeedDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let detail = viewModel.state.detail, let header = viewModel.header {
                loadedFeedDetailView(detail: detail, header: header)
            } else {
               LoadingView()
            }
        }
        .background(WSSColor.wssWhite.swiftUIColor)
        .toolbar {
            createFeedDetailToolBarContent()
        }
        .onAppear {
            Task { await viewModel.handle(.load) }
        }
    }

    @ViewBuilder
    private func loadedFeedDetailView(detail: FeedDetail, header: FeedHeader) -> some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    WSSFeadHeaderView(
                        header: header,
                        profileImageTapped: { print("유저 \(String(describing: detail.author.userId?.value)) 페이지로 이동") },
                        showThreeDotsButton: false
                    )
                    
                    Spacer().frame(height: 14)
                    
                    HStack(spacing: 0) {
                        Text(detail.feedContent)
                            .applyWSSFont(.body2)
                            .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                
                Spacer().frame(height: 30)
                
                if viewModel.hasAttachedImages {
                    FeedDetailAttachImageBlock(imageURLs: viewModel.attachedImageURLs)
                    
                    Spacer().frame(height: 16)
                }
                
                if let novel = viewModel.connectedNovel {
                    FeedDetailLinkNovelBlock(
                        imageURL: novel.imageURL,
                        title: novel.title,
                        novelDescription: novel.description,
                        genre: novel.genre,
                        feedWriteUsername: header.nickname,
                        feedWriteUserRating: novel.feedUserRating,
                        totalRating: novel.totalRating
                    )
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        print("\(String(describing: detail.connectedNovel?.basicInfo.id.value)) 으로 이동")
                    }
                    
                    Spacer().frame(height: 30)
                }
                
                WSSFeedReactView(
                    react: WSSFeedReact(
                        likeCount: detail.likeCount,
                        commentCount: detail.commentCount
                    ),
                    isLiked: detail.isLiked,
                    likeButtonTapped: { Task { await viewModel.handle(.toggleLike) } }
                )
                .padding(.horizontal, 16)
                
                // MARK: - 구분선
                
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 0.7)
                        .foregroundStyle(WSSColor.wssGray70.swiftUIColor)
                    Rectangle()
                        .frame(height: 7)
                        .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
                }
                
                //MARK: - 댓글
                
                Spacer().frame(height: 16)
                
                ForEach(viewModel.state.comments, id: \.id) { comment in
                    CommentRow(
                        profileImageURL: comment.user.profileImage,
                        username:   comment.user.nickname,
                        content: comment.content,
                        createdAt: comment.createdDate,
                        myComment: true
                    )
                    
                    Spacer().frame(height: 22)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            //.navigationBarBackButtonHidden() // 데모앱을 위한 임시 주석
            
            if showFeedDropdown {
                WSSDropdownMenu(
                    items: [
                        WSSDropdownItem(
                            title: "스포일러 신고",
                            action: { },
                            textColor: WSSColor.wssSecondary100.swiftUIColor
                        ),
                        WSSDropdownItem(
                            title: "부적절한 표현 신고",
                            action: { },
                            textColor: WSSColor.wssSecondary100.swiftUIColor
                        )
                    ])
                .frame(width: 190)
                .padding(.trailing, 20)
            }
        }
    }

    @ToolbarContentBuilder
    private func createFeedDetailToolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            WSSImage.icNavigateLeft.swiftUIImage
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .onTapGesture {
                    print("뒤로 이동")
                }
        }

        ToolbarItem(placement: .topBarTrailing) {
            WSSImage.icThreedots.swiftUIImage
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .frame(width: 38, height: 38)
                .onTapGesture {
                    showFeedDropdown.toggle()
                }
        }
    }
}

#Preview {
    NavigationStack {
        FeedDetailView(viewModel: FeedDetailViewModel(
            feedID: FeedID(1),
            loadFeedDetailUseCase: PreviewLoadFeedDetailUseCase(),
            feedLikeUsecase: PreviewFeedLikeUseCase(),
            loadCommentsUseCase: PreviewLoadCommentsUseCase(),
            createCommentUseCase: PreviewCreateCommentUseCase(),
            deleteCommentUseCase: PreviewDeleteCommentUseCase(),
            editCommentUseCase: PreviewEditCommentUseCase(),
            reportSpoilerFeedUseCase: PreviewReportSpoilerFeedUseCase(),
            reportImproperFeedUseCase: PreviewReportImproperFeedUseCase(),
            reportSpoilerCommentUseCase: PreviewReportSpoilerCommentUseCase(),
            reportImproperCommentUseCase: PreviewReportImproperCommentUseCase()
        ))
    }
}

private struct PreviewLoadFeedDetailUseCase: LoadFeedDetailUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> FeedDetail {
        FeedDetail(
            id: feedID,
            author: Author(
                userId: UserID(1),
                nickname: "구리구리스",
                profileImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg")
            ),
            createdDate: "2001년 10월 3일",
            isModified: true,
            feedContent: "여주가 세계를 구함 이름이 나여주입니다ㅋㅋㅋ\n\n 읽던 소설이 세계멸망엔딩나서 댓글달았다가 그 세계의 본인에게 빙의하게 되었는데 S급 힐러에 세계관 관련 중요스킬까지 얻고 시작하는 스토리. 121화 최신화 기준 큰 고구마없고 남주가 질서선 댕댕이입니다.",
            feedImageURLs: [
                URL(string: "https://i.pinimg.com/1200x/a7/41/22/a74122c74fab445033dcc8b3544f5dd1.jpg"),
                URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg")
            ],
            connectedNovel: ConnectedNovelDetail(
                basicInfo: ConnectedNovel(
                    id: NovelID(1),
                    title: "짐승 대공의 부인이 되었습니다",
                    genre: .modernFantasy,
                    rating: 2.34
                ),
                thumbnailImageURL: URL(string: "https://i.pinimg.com/736x/fe/61/a3/fe61a3449cb9c20f9c304ad2d95edfd7.jpg"),
                descirption: "꼰대 사수에게 석 달간 볶여 가며 끝낸 프로젝트에서 거나하게 성과급을 받았는데, 써 보지도 못하고 죽어버렸다. 그것만 해도 어이가 없는데, 눈 떠보니 죽기 전에 읽었던 <괴물 대공님의 부인>에서 남주에게 집착하다 끔살 당한 전처가",
                feedWriterRating: 5.0
            ),
            likeCount: 123,
            isLiked: true,
            commentCount: 1
        )
    }
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) { }
    func unlike(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewLoadCommentsUseCase: LoadCommentsUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> [FeedComment] {
        [
            FeedComment(
                id: CommentID(3),
                user: Author(
                    userId: UserID(1),
                    nickname: "손흥민",
                    profileImage: URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg")
                ),
                createdDate: "2011년 12월 2일",
                content: "댓글입니다",
                isModified: true,
                isSpoiler: false,
                isBlocked: false,
                isHidden: false
            ),
            FeedComment(
                id: CommentID(3),
                user: Author(
                    userId: UserID(1),
                    nickname: "손흥민",
                    profileImage: URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg")
                ),
                createdDate: "2011년 12월 2일",
                content: "댓글입니다",
                isModified: true,
                isSpoiler: false,
                isBlocked: false,
                isHidden: false
            )
            ,FeedComment(
                id: CommentID(3),
                user: Author(
                    userId: UserID(1),
                    nickname: "손흥민",
                    profileImage: URL(string: "https://i.pinimg.com/1200x/1b/24/4f/1b244f2796bc860e9ffe1e8f9162ce7c.jpg")
                ),
                createdDate: "2011년 12월 2일",
                content: "댓글입니다",
                isModified: true,
                isSpoiler: false,
                isBlocked: false,
                isHidden: false
            )
        ]
    }
}

private struct PreviewCreateCommentUseCase: CreateCommentUseCase {
    func execute(feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError) { }
}

private struct PreviewDeleteCommentUseCase: DeleteCommentUseCase {
    func execute(commentID: CommentID, feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewEditCommentUseCase: EditCommentUseCase {
    func execute(commentID: CommentID, feedID: FeedID, _ draft: CommentDraft) async throws(RepositoryError) { }
}

private struct PreviewReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
}

private struct PreviewReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
}

private struct PreviewReportSpoilerCommentUseCase: ReportSpoilerCommentUseCase {
    func execute(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) { }
}

private struct PreviewReportImproperCommentUseCase: ReportImproperCommentUseCase {
    func execute(feedID: FeedID, commentID: CommentID) async throws(RepositoryError) { }
}

