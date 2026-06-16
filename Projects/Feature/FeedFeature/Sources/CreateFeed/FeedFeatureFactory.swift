//
//  FeedFeatureFactory.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation
import SwiftUI

import BaseDomain
import FeedDomain
import NovelDomain
import CommentDomain

/// FeedFeature 모듈의 외부 진입점.
public enum FeedFeatureFactory {

    /// 실제 UseCase를 주입해 CreateFeedView를 생성한다.
    @MainActor
    public static func makeCreateFeedView(
        createFeedUseCase: CreateFeedUseCase,
        searchNovelUseCase: SearchNovelUseCase
    ) -> CreateFeedView {
        CreateFeedView(
            viewModel: CreateFeedViewModel(
                createFeedUseCase: createFeedUseCase,
                searchNovelUseCase: searchNovelUseCase,
                initialDraft: emptyDraft()
            )
        )
    }

    /// 네트워크 없이 ViewModel/View 동작만 확인하기 위한 임시 진입점.
    /// 제출 시 1초 후 성공으로 처리한다.
    @MainActor
    public static func makeCreateFeedPreviewView() -> CreateFeedView {
        makeCreateFeedView(createFeedUseCase: StubCreateFeedUseCase(),
                           searchNovelUseCase: StubSearchNovelUseCase())
    }

    /// 실제 UseCase를 주입해 FeedDetailView를 생성한다.
    /// 진입 시 `feedID`만 받고, 상세/댓글은 화면에서 직접 load한다.
    @MainActor
    public static func makeFeedDetailView(
        feedID: FeedID,
        loadFeedDetailUseCase: LoadFeedDetailUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        loadCommentsUseCase: LoadCommentsUseCase,
        createCommentUseCase: CreateCommentUseCase,
        deleteCommentUseCase: DeleteCommentUseCase,
        editCommentUseCase: EditCommentUseCase
    ) -> some View {
        FeedDetailView(
            viewModel: FeedDetailViewModel(
                feedID: feedID,
                loadFeedDetailUseCase: loadFeedDetailUseCase,
                feedLikeUsecase: feedLikeUseCase,
                loadCommentsUseCase: loadCommentsUseCase,
                createCommentUseCase: createCommentUseCase,
                deleteCommentUseCase: deleteCommentUseCase,
                editCommentUseCase: editCommentUseCase
            )
        )
    }

    private static func emptyDraft() -> FeedDraft {
        FeedDraft(
            content: "",
            isSpoiler: false,
            isPrivate: false,
            attachedImages: []
        )
    }
}

/// 검증용 Stub — 항상 1초 후 성공.
private struct StubCreateFeedUseCase: CreateFeedUseCase {
    func execute(_ draft: FeedDraft, imageDatas: [Data]) async throws(RepositoryError) {
        try? await Task.sleep(for: .seconds(1))
    }
}

private struct StubSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String) async throws(BaseDomain.RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: stubNovels, hasNext: false), 0)
    }
    
    func searchByFilter(_ filter: NovelDomain.SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [], hasNext: false), 0)
    }
}

public let stubNovels: [Novel] = [
    Novel(
        id: NovelID(1),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/58/0a/13/580a13692bdefec82fc37cdc8e87e331.jpg"),
        title: "회귀한 천재 마법사",
        authors: ["김작가"],
        genres: [],
        interestCount: 12543,
        rating: 4.8,
        ratingCount: 3214
    ),
    Novel(
        id: NovelID(2),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/12/49/04/124904e3933472601d83f8ff771def50.jpg"),
        title: "멸망한 세계의 검신",
        authors: ["이판타지"],
        genres: [],
        interestCount: 8932,
        rating: 4.6,
        ratingCount: 1875
    ),
    Novel(
        id: NovelID(3),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/fc/11/ed/fc11ed1b94cc32feefc9e40f1b2d8f65.jpg"),
        title: "재벌집 막내아들",
        authors: ["산경"],
        genres: [],
        interestCount: 25431,
        rating: 4.9,
        ratingCount: 10234
    ),
    Novel(
        id: NovelID(4),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/b9/94/6e/b9946e9db54c175c490b54dfd40adc41.jpg"),
        title: "나 혼자만 레벨업",
        authors: ["추공"],
        genres: [],
        interestCount: 51234,
        rating: 4.9,
        ratingCount: 25431
    ),
    Novel(
        id: NovelID(5),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/d6/49/7a/d6497aefa2800044f63cbf66889fb4df.jpg"),
        title: "전지적 독자 시점",
        authors: ["싱숑"],
        genres: [],
        interestCount: 43892,
        rating: 4.8,
        ratingCount: 19876
    ),
    Novel(
        id: NovelID(6),
        thumbnailImage: URL(string: "https://i.pinimg.com/1200x/20/55/03/20550396102b05d92c4a04f9136352d5.jpg"),
        title: "아카데미의 천재 검술가",
        authors: ["홍길동", "김철수"],
        genres: [],
        interestCount: 7234,
        rating: 4.3,
        ratingCount: 912
    ),
    Novel(
        id: NovelID(7),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/01/7b/8d/017b8dd944076cb85da607fe2d94237a.jpg"),
        title: "21세기 대군 부인",
        authors: ["박작가"],
        genres: [],
        interestCount: 16782,
        rating: 4.7,
        ratingCount: 3842
    ),
    Novel(
        id: NovelID(8),
        thumbnailImage: URL(string: "https://i.pinimg.com/736x/69/80/22/69802233c6656902b1eedb94f6b338b2.jpg"),
        title: "망겜의 성기사",
        authors: ["최작가"],
        genres: [],
        interestCount: 5321,
        rating: 4.1,
        ratingCount: 623
    )]
