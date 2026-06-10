//
//  FeedFeatureFactory.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation

import BaseDomain
import FeedDomain
import NovelDomain

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
        return (Paginated(items: [], hasNext: false), 0)
    }
    
    func searchByFilter(_ filter: NovelDomain.SearchFilter) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        return (Paginated(items: [], hasNext: false), 0)
    }
}
