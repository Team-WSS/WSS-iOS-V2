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

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: FeedDetailViewModel

    /// 피드 수정 진입 콜백. 대상 피드 ID와 prefill용 Draft를 전달한다.
    /// 목적지(CreateFeed 수정 화면 등)는 상위 조정 계층이 결정한다.
    private let onEditFeed: (FeedID, FeedDraft) -> Void

    @State private var selectedCommentID: CommentID? = nil
    @State private var selectedCommentIsMine: Bool = false
    
    // 드롭다운 변수
    @State private var showFeedDropdown: Bool = false
    @State private var showCommentDropdown: Bool = false
    
    // 알럿 변수
    @State private var showSpoilerReportAlert: Bool = false
    @State private var showImproperReportAlert: Bool = false
    @State private var showSpoilerReceivedAlert: Bool = false
    @State private var showImproperReceivedAlert: Bool = false
    @State private var showDeleteCommentAlert: Bool = false
    @State private var showDeleteFeedAlert: Bool = false
    
    init(
        viewModel: FeedDetailViewModel,
        onEditFeed: @escaping (FeedID, FeedDraft) -> Void = { _, _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onEditFeed = onEditFeed
    }
    
    var body: some View {
        Group {
            if let detail = viewModel.state.detail {
                let header = FeedHeader(
                    profileImageURL: detail.author.profileImage,
                    nickname: detail.author.nickname,
                    createdDate: detail.createdDate,
                    isEdited: detail.isModified
                )
                loadedFeedDetailView(detail: detail, header: header)
            } else {
                LoadingView()
            }
        }
        .background(WSSColor.wssWhite.swiftUIColor)
        .overlay(alignment: .topTrailing) {
            if showFeedDropdown {
                WSSDropdownMenu(items: feedDropdownItems())
                    .frame(width: 190)
                    .padding(.trailing, 20)
                    .padding(.top, 4)
            }
        }
        .toolbar {
            createFeedDetailToolBarContent()
        }
        .onTapGesture {
            if showFeedDropdown { showFeedDropdown = false }
            if showCommentDropdown { showCommentDropdown = false }
        }
        .onAppear {
            Task { await viewModel.handle(.load) }
        }
    }
    
    @ViewBuilder
    private func loadedFeedDetailView(detail: FeedDetail, header: FeedHeader) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                
                // MARK: - 피드 본문
                
                VStack(spacing: 0) {
                    // 피드 헤더 - 프로필
                    WSSFeadHeaderView(
                        header: header,
                        profileImageTapped: { print("유저 \(String(describing: detail.author.userId?.value)) 페이지로 이동") },
                        showThreeDotsButton: false
                    )
                    
                    Spacer().frame(height: 14)
                    
                    // 피드 내용
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
                
                // 피드 첨부 이미지
                if !detail.feedImageURLs.isEmpty {
                    FeedDetailAttachImageBlock(imageURLs: detail.feedImageURLs)
                    
                    Spacer().frame(height: 16)
                }
                
                // 피드 연결 작품
                if let novel = viewModel.state.detail?.connectedNovel {
                    FeedDetailLinkNovelBlock(
                        imageURL: novel.thumbnailImageURL,
                        title: novel.basicInfo.title,
                        novelDescription: novel.descirption,
                        genre: novel.basicInfo.genre,
                        feedWriteUsername: header.nickname,
                        feedWriteUserRating: novel.feedWriterRating ?? 0,
                        totalRating: novel.basicInfo.rating ?? 0
                    )
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        print("\(String(describing: detail.connectedNovel?.basicInfo.id.value)) 으로 이동")
                    }
                    
                    Spacer().frame(height: 30)
                }
                
                // 피드 리액션
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
                
                Spacer().frame(height: 16)
                
                //MARK: - 댓글
                
                ForEach(viewModel.state.comments, id: \.id) { comment in
                    let isMine = viewModel.isMyComment(comment)
                    CommentRow(
                        userID: comment.user.userId?.value ?? 1,
                        profileImageURL: comment.user.profileImage,
                        username:   comment.user.nickname,
                        content: comment.content,
                        createdAt: comment.createdDate,
                        isEdited: comment.isModified,
                        myComment: isMine,
                        threeDotsAction: {
                            selectedCommentID = comment.id
                            selectedCommentIsMine = isMine
                            showCommentDropdown.toggle()
                        }
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if showCommentDropdown, selectedCommentID == comment.id {
                            WSSDropdownMenu(items: commentDropdownItems())
                                .frame(width: 190)
                                .padding(.trailing, 2)
                                .padding(.bottom, 40)
                        }
                    }
                    
                    Spacer().frame(height: 22)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            //.navigationBarBackButtonHidden()
            .padding(.bottom, 50)
            
            // MARK: - 댓글 입력
            
            FeedDetailCommentInputBar(
                text:
                    Binding(
                        get: { viewModel.state.commentText },
                        set: { value in Task { await viewModel.handle(.updateCommentText(value)) }}
                    ),
                sendAction: { Task { await viewModel.handle(.submitComment) } }
            )
        }
        
        .showWSSAlert(
            isPresented: $showSpoilerReportAlert,
            type: .reportSpoilerContent,
            buttonActions: [
                { showSpoilerReportAlert.toggle() },
                {
                    Task {
                        if let commentID = selectedCommentID {
                            await viewModel.handle(.reportSpoilerComment(commentID))
                        } else {
                            await viewModel.handle(.reportSpoilerFeed)
                        }
                        showSpoilerReceivedAlert = true
                    }
                }
            ]
        )
        .showWSSAlert(
            isPresented: $showImproperReportAlert,
            type: .reportImproperContent,
            buttonActions: [
                { showImproperReportAlert.toggle() },
                {
                    Task {
                        if let commentID = selectedCommentID {
                            await viewModel.handle(.reportImproperComment(commentID))
                        } else {
                            await viewModel.handle(.reportImproperFeed)
                        }
                        showImproperReceivedAlert = true
                    }
                }
            ]
        )
        .showWSSAlert(
            isPresented: $showSpoilerReceivedAlert,
            type: .receivedReportSpoilerContent,
            buttonActions: [
                {
                    selectedCommentID = nil
                    showSpoilerReceivedAlert.toggle()
                }
            ]
        )
        .showWSSAlert(
            isPresented: $showImproperReceivedAlert,
            type: .receivedReportImproperContent,
            buttonActions: [
                {
                    selectedCommentID = nil
                    showImproperReceivedAlert.toggle()
                }
            ]
        )
        .showWSSAlert(
            isPresented: $showDeleteCommentAlert,
            type: .deleteMyComment,
            buttonActions: [
                {
                    selectedCommentID = nil
                    showDeleteCommentAlert.toggle()
                },
                {
                    if let commentID = selectedCommentID {
                        Task { await viewModel.handle(.deleteComment(commentID)) }
                    }
                    selectedCommentID = nil
                    showDeleteCommentAlert.toggle()
                }
            ]
        )
        .showWSSAlert(
            isPresented: $showDeleteFeedAlert,
            type: .deleteMyFeed,
            buttonActions: [
                { showDeleteFeedAlert.toggle() },
                {
                    showDeleteFeedAlert.toggle()
                    Task {
                        await viewModel.handle(.deleteFeed)
                        if viewModel.state.didDeleteFeed { dismiss() }
                    }
                }
            ]
        )
    }
    
    //MARK: - 툴바 아이템
    
    @ToolbarContentBuilder
    private func createFeedDetailToolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            WSSImage.icNavigateLeft.swiftUIImage
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .onTapGesture {
                    dismiss()
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
    
    //MARK: - 피드 드롭다운
    
    private func feedDropdownItems() -> [WSSDropdownItem] {
        if viewModel.isMyFeed {
            return [
                WSSDropdownItem(
                    title: "수정",
                    action: {
                        showFeedDropdown = false
                        if let feedID = viewModel.state.detail?.id,
                           let draft = viewModel.editingDraft {
                            onEditFeed(feedID, draft)
                        }
                    }
                ),
                WSSDropdownItem(
                    title: "삭제",
                    action: {
                        showFeedDropdown = false
                        showDeleteFeedAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ]
        } else {
            return [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        showFeedDropdown = false
                        selectedCommentID = nil
                        showSpoilerReportAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        showFeedDropdown = false
                        selectedCommentID = nil
                        showImproperReportAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ]
        }
    }
    
    //MARK: - 댓글 드롭다운
    
    private func commentDropdownItems() -> [WSSDropdownItem] {
        if selectedCommentIsMine {
            return [
                WSSDropdownItem(
                    title: "수정",
                    action: {
                        showCommentDropdown = false
                        if let commentID = selectedCommentID {
                            Task { await viewModel.handle(.beginEditingComment(commentID)) }
                        }
                    }
                ),
                WSSDropdownItem(
                    title: "삭제",
                    action: {
                        showCommentDropdown = false
                        showDeleteCommentAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ]
        } else {
            return [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        showCommentDropdown = false
                        showSpoilerReportAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                    
                    
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        showCommentDropdown = false
                        showImproperReportAlert = true
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ]
        }
    }
}

#Preview {
    NavigationStack {
        FeedDetailView(viewModel: FeedDetailViewModel(
            feedID: FeedID(1),
            currentUserID: 2,
            loadFeedDetailUseCase: PreviewLoadFeedDetailUseCase(),
            feedLikeUsecase: PreviewFeedLikeUseCase(),
            deleteFeedUseCase: PreviewDeleteFeedUseCase(),
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
                userId: UserID(2),
                nickname: "구리구리스",
                profileImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg")
            ),
            createdDate: "2001년 10월 3일",
            isModified: true,
            feedContent: "여주가 세계를 구함 이름이 나여주입니다ㅋㅋㅋ\n\n 읽던 소설이 세계멸망엔딩나서 댓글달았다가 그 세계의 본인에게 빙의하게 되었는데 S급 힐러에 세계관 관련 중요스킬까지 얻고 시작하는 스토리. 121화 최신화 기준 큰 고구마없고 남주가 질서선 댕댕이입니다.",
            feedImageURLs: [URL(string: "https://i.pinimg.com/736x/fe/61/a3/fe61a3449cb9c20f9c304ad2d95edfd7.jpg")],
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
            commentCount: 1,
            isSpoiler: true,
            isPublic: true
        )
    }
}

private struct PreviewDeleteFeedUseCase: DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) { }
    func unlike(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewLoadCommentsUseCase: LoadCommentsUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) -> [FeedComment] {
        [
            FeedComment(id: CommentID(1),
                        user: Author(userId: UserID(2),
                                     nickname: "구리스",
                                     profileImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg")),
                        createdDate: "방금 전",
                        content: "웃기다",
                        isModified: false,
                        isSpoiler: false,
                        isBlocked: false,
                        isHidden: false),
            FeedComment(id: CommentID(2),
                        user: Author(userId: UserID(2),
                                     nickname: "구리스",
                                     profileImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg")),
                        createdDate: "방금 전",
                        content: "웃기다",
                        isModified: false,
                        isSpoiler: false,
                        isBlocked: false,
                        isHidden: false),
            FeedComment(id: CommentID(3),
                        user: Author(userId: UserID(2),
                                     nickname: "구리스",
                                     profileImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg")),
                        createdDate: "방금 전",
                        content: "웃기다",
                        isModified: false,
                        isSpoiler: false,
                        isBlocked: false,
                        isHidden: false)
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

