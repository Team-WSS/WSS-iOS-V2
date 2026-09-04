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
import ProfileDomain
import WSSComponent
import DesignSystem

struct FeedDetailView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: FeedDetailViewModel

    @State private var selectedCommentID: CommentID? = nil
    @State private var selectedCommentIsMine: Bool = false

    @FocusState private var isCommentFocused: Bool

    /// 댓글 입력 `TextField`는 VM 상태에 직접 물리지 않고 이 로컬 버퍼를 거친다 — 500자 clamp를
    /// `Binding.set`에서 바로 하면 네이티브 필드가 초과분을 화면에 그대로 들고 있는 함정이 있어서다
    /// (Feature/UserPageFeature CLAUDE.md의 글자수 제한 TextField 2단계 패턴, #222 복원).
    @State private var commentDraft: String = ""

    // 이미지 확대 뷰
    @State private var selectedImage: SelectedImage?

    // 드롭다운 변수
    @State private var showFeedDropdown: Bool = false
    @State private var showCommentDropdown: Bool = false

    private let onNovelTapped: (NovelID) -> Void
    /// 내 글 드롭다운의 "수정" → 수정 화면 진입 콜백. 대상 피드 `FeedID`만 넘긴다 — 실제 데이터 로드는
    /// 수정 화면 자신이 하므로 화면 전환(`makeEditFeedView` 조립)은 호출자(App 조정 계층)가 값만 그대로
    /// 받아 하면 된다.
    private let onEditFeedTapped: (FeedID) -> Void
    /// 작성자 프로필(이미지+닉네임) 탭 → 유저 프로필 진입 콜백. 실제 화면 전환(`UserPageAssembly` 조립)은
    /// 호출자(App 조정 계층)가 수행한다(`SosoFeedView`의 `onUserProfileTapped`와 동일 계약).
    private let onUserProfileTapped: (UserID) -> Void

    init(
        viewModel: FeedDetailViewModel,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onUserProfileTapped: @escaping (UserID) -> Void = { _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelTapped = onNovelTapped
        self.onEditFeedTapped = onEditFeedTapped
        self.onUserProfileTapped = onUserProfileTapped
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "") {
                dismiss()
            } trailing: {
                WSSImage.icThreedots.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 38, height: 38)
                    .onTapGesture {
                        showFeedDropdown.toggle()
                    }
            }

        Group {
            if let detail = viewModel.state.detail {
                let header = FeedHeader(
                    profileImageURL: detail.author.profileImage,
                    nickname: detail.author.nickname,
                    createdDate: detail.createdDate,
                    isEdited: detail.isModified
                )
                loadedFeedDetailView(detail: detail, header: header)
            } else if let error = viewModel.state.detailLoadFailed {
                NetworkErrorView(error: error) { Task { await viewModel.handle(.load) } }
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
        .onTapGesture {
            if showFeedDropdown { showFeedDropdown = false }
            if showCommentDropdown { showCommentDropdown = false }
            isCommentFocused = false
        }
        }
        .wssCustomNavigationBar()
        .onAppear {
            Task { await viewModel.handle(.load) }
        }
        .fullScreenCover(item: $selectedImage) { item in
            FeedDetailImageViewer(
                imageURLs: viewModel.state.detail?.feedImageURLs ?? [],
                initialIndex: item.index
            )
        }
        // 이 화면의 모든 알럿(신고 확인/완료, 삭제 확인, 피드 접근 불가)은 VM의 `state.alert` 하나로 표현된다.
        // detail이 로드되지 않은 상태에서도 떠야 하므로(피드 접근 불가) 최상위에 건다.
        .showWSSAlert(
            isPresented: alertBinding,
            type: alertType,
            buttonActions: alertActions
        )
        .showWSSToast(isPresented: unavailableUserToastBinding, type: .unknownUser)
        .showWSSToast(isPresented: actionFailedToastBinding, type: .networkDelay)
    }
    
    @ViewBuilder
    private func loadedFeedDetailView(detail: FeedDetail, header: FeedHeader) -> some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {

                    // MARK: - 피드 본문

                    VStack(spacing: 0) {
                        // 피드 헤더 - 프로필
                        WSSFeadHeaderView(
                            header: header,
                            profileImageTapped: {
                                guard let userID = detail.author.accessibleUserId else {
                                    Task { await viewModel.handle(.userProfileUnavailableTapped) }
                                    return
                                }
                                onUserProfileTapped(userID)
                            },
                            isProfileTappable: !viewModel.isMyFeed,
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
                        FeedDetailAttachImageBlock(
                            imageURLs: detail.feedImageURLs,
                            onImageTapped: { index in
                                selectedImage = SelectedImage(id: index)
                            }
                        )

                        Spacer().frame(height: 16)
                    }

                    // 피드 연결 작품
                    if let novel = viewModel.state.detail?.connectedNovel,
                       let genre = novel.basicInfo.genre {
                        FeedDetailLinkNovelBlock(
                            imageURL: novel.thumbnailImageURL,
                            title: novel.basicInfo.title,
                            novelDescription: novel.descirption,
                            genre: genre,
                            feedWriteUsername: header.nickname,
                            feedWriteUserRating: novel.feedWriterRating ?? 0,
                            totalRating: novel.basicInfo.rating ?? 0
                        )
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            onNovelTapped(novel.basicInfo.id)
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
                            profileImageURL: comment.user.profileImage,
                            username:   comment.user.nickname,
                            content: comment.content,
                            createdAt: comment.createdDate,
                            isEdited: comment.isModified,
                            visibility: comment.visibility,
                            myComment: isMine,
                            profileImageTapped: {
                                guard let userID = comment.user.accessibleUserId else {
                                    Task { await viewModel.handle(.userProfileUnavailableTapped) }
                                    return
                                }
                                onUserProfileTapped(userID)
                            },
                            threeDotsAction: {
                                if showCommentDropdown, selectedCommentID == comment.id {
                                    showCommentDropdown = false
                                } else {
                                    selectedCommentID = comment.id
                                    selectedCommentIsMine = isMine
                                    showCommentDropdown = true
                                }
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

                    Color.clear
                        .frame(height: 1)
                        .id("bottomAnchor")
                }
                .scrollBounceBehavior(.basedOnSize)
                .padding(.bottom, 50)
                .onChange(of: isCommentFocused) { _, isFocused in
                    guard isFocused else { return }
                    scrollToBottom(proxy, afterMilliseconds: 300)
                }
                .onChange(of: viewModel.state.comments.count) { oldCount, newCount in
                    guard newCount > oldCount else { return }
                    scrollToBottom(proxy, afterMilliseconds: 0)
                }
            }

            // MARK: - 댓글 입력
            
            FeedDetailCommentInputBar(
                text: $commentDraft,
                profileImageURL: viewModel.state.currentUserProfileImageURL,
                sendAction: {
                    Task {
                        let wasEditing = viewModel.state.editingCommentID != nil
                        await viewModel.handle(.submitComment)
                        if wasEditing {
                            isCommentFocused = false
                        }
                    }
                },
                isSubmitting: viewModel.state.isSubmittingComment,
                isSendEnabled: isCommentSendEnabled,
                externalFocus: $isCommentFocused
            )
            // 로컬 버퍼 → clamp → (초과면 로컬 재대입해 네이티브 필드 되돌림 / 아니면 VM 전달)의 2단계.
            .onChange(of: commentDraft) { _, newValue in
                let clamped = String(newValue.prefix(CommentDraft.maxContentCount))
                if clamped != newValue {
                    commentDraft = clamped
                    return
                }
                Task { await viewModel.handle(.updateCommentText(clamped)) }
            }
            // 수정 진입(본문 채움)·전송 후 비우기·취소처럼 VM이 텍스트를 바꾸면 로컬 버퍼를 맞춘다.
            .onChange(of: viewModel.state.commentText) { _, newValue in
                guard commentDraft != newValue else { return }
                commentDraft = newValue
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
                        if let feedID = viewModel.state.detail?.id {
                            onEditFeedTapped(feedID)
                        }
                    },
                    textColor: WSSColor.wssBlack.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "삭제",
                    action: {
                        showFeedDropdown = false
                        Task { await viewModel.handle(.presentAlert(.deleteFeed)) }
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
                        Task { await viewModel.handle(.presentAlert(.reportSpoiler(commentID: nil))) }
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        showFeedDropdown = false
                        selectedCommentID = nil
                        Task { await viewModel.handle(.presentAlert(.reportImproper(commentID: nil))) }
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
                            Task {
                                await viewModel.handle(.beginEditingComment(commentID))
                                isCommentFocused = true
                            }
                        }
                    }
                ),
                WSSDropdownItem(
                    title: "삭제",
                    action: {
                        showCommentDropdown = false
                        if let commentID = selectedCommentID {
                            Task { await viewModel.handle(.presentAlert(.deleteComment(commentID))) }
                        }
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
                        Task { await viewModel.handle(.presentAlert(.reportSpoiler(commentID: selectedCommentID))) }
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        showCommentDropdown = false
                        Task { await viewModel.handle(.presentAlert(.reportImproper(commentID: selectedCommentID))) }
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ]
        }
    }

    //MARK: - 스크롤

    private func scrollToBottom(_ proxy: ScrollViewProxy, afterMilliseconds delay: Int) {
        Task {
            if delay > 0 {
                try? await Task.sleep(for: .milliseconds(delay))
            }
            withAnimation {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }

    //MARK: - 댓글 전송 활성 조건

    /// 전송 버튼 활성 조건: 내용이 비어있지 않고, **수정 모드면** 원본 댓글과 달라야 한다
    /// (무변경 재전송 방지, V1 parity #222). 작성 모드는 비어있지 않으면 항상 활성.
    private var isCommentSendEnabled: Bool {
        let trimmed = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let editingID = viewModel.state.editingCommentID,
           let original = viewModel.state.comments.first(where: { $0.id == editingID })?.content {
            return commentDraft != original
        }
        return true
    }

    //MARK: - 알럿 Presentation

    /// VM의 의미 알럿(`state.alert`) → 표시 여부. "취소" 없이 확인 한 번뿐인 알럿(`feedUnavailable` 등)도
    /// 버튼 액션에서 명시적으로 `dismissAlert`를 호출하므로 set은 쓰이지 않는다.
    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.alert != nil },
            set: { _ in }
        )
    }

    private var unavailableUserToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isUnavailableUserToastPresented },
            set: { newValue in
                if !newValue { Task { await viewModel.handle(.dismissUnavailableUserToast) } }
            }
        )
    }

    /// 댓글 작성/수정/삭제·피드 삭제 실패 시 뜨는 "네트워크 지연" 토스트(#222 조용한 실패 복원).
    private var actionFailedToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isActionFailedToastPresented },
            set: { newValue in
                if !newValue { Task { await viewModel.handle(.dismissActionFailedToast) } }
            }
        )
    }

    /// VM의 의미 알럿 → 실제 `WSSAlertType`(문구·버튼 개수) 매핑. `nil`이면 안 뜨므로 값은 임의.
    private var alertType: WSSAlertType {
        switch viewModel.state.alert {
        case .reportSpoiler:
            return .reportSpoilerContent
        case .reportImproper:
            return .reportImproperContent
        case .reportSpoilerCompleted:
            return .receivedReportSpoilerContent
        case .reportImproperCompleted:
            return .receivedReportImproperContent
        case .deleteComment:
            return .deleteMyComment
        case .deleteFeed:
            return .deleteMyFeed
        case .feedUnavailable, nil:
            return .alreadyDeletedFeed
        }
    }

    /// VM의 의미 알럿 → 버튼 액션. 신고 확인은 완료 알럿으로 전환되고, 삭제/안내는 실행 후 닫힌다.
    private var alertActions: [() -> Void] {
        switch viewModel.state.alert {
        case .reportSpoiler, .reportImproper:
            return [
                { Task { await viewModel.handle(.dismissAlert) } },
                { Task { await viewModel.handle(.confirmAlert) } }
            ]
        case .reportSpoilerCompleted, .reportImproperCompleted:
            return [
                {
                    selectedCommentID = nil
                    Task { await viewModel.handle(.dismissAlert) }
                }
            ]
        case .deleteComment:
            return [
                {
                    selectedCommentID = nil
                    Task { await viewModel.handle(.dismissAlert) }
                },
                {
                    selectedCommentID = nil
                    Task { await viewModel.handle(.confirmAlert) }
                }
            ]
        case .deleteFeed:
            return [
                { Task { await viewModel.handle(.dismissAlert) } },
                {
                    Task {
                        await viewModel.handle(.confirmAlert)
                        if viewModel.state.didDeleteFeed { dismiss() }
                    }
                }
            ]
        case .feedUnavailable:
            return [ { dismiss() } ]
        case nil:
            return []
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
            reportImproperCommentUseCase: PreviewReportImproperCommentUseCase(),
            loadProfileUseCase: PreviewLoadProfileUseCase()
        ), onNovelTapped: { print("작품 상세 진입: \($0)") })
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

private struct PreviewLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(
            nickname: "구리구리스",
            introduction: "",
            characterImage: URL(string: "https://i.pinimg.com/736x/07/b1/33/07b1330bb9b7b96ea5845371c924397a.jpg"),
            isPublic: true,
            genrePreferences: []
        )
    }
}

