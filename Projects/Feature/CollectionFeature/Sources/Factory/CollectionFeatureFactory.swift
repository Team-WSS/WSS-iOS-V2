//
//  CollectionFeatureFactory.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import SearchDomain
import NovelDomain
import Logger

/// 모듈의 유일한 public 진입점. 화면이 둘 이상(생성/상세/리스트 등, #191 이슈 범위)일 예정이라
/// 대표 `makeView` 대신 화면마다 `make<Screen>View`로 짓는다.
///
/// "작품 추가" 화면(`CollectionSearchNovelView`)과 그 안의 "서재에서 추가" 화면
/// (`CollectionMyLibrarySelectView`)은 이 Factory에 노출되지 않는다 — `CreateCollectionView`가 자기
/// 내부에서만 push하는 로컬 화면이라(`ReadingPeriodSheet`와 같은 위상) 모듈 밖(App/Demo)이 알 이유가
/// 없다. 대신 그 화면들이 검색·서재 조회에 쓸 UseCase만 여기서 받아 내려보낸다.
public enum CollectionFeatureFactory {

    /// - Parameters:
    ///   - searchNovelUseCase: "작품 추가" 화면(내부 로컬 push)의 작품 검색용 — `FeedFeature`의 연결
    ///     작품 검색과 같은 이유로 `SearchDomain`을 쓴다.
    ///   - loadMyLibraryUseCase: "작품 추가" 화면의 "서재에서 추가"(내부 로컬 push)의 서재 조회용 —
    ///     서재 Domain 코드는 별도 모듈이 아니라 `NovelDomain`에 있다(`LibraryFeature`와 같은 이유).
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다. "작품 추가"/"서재에서 추가" 화면도 같은 콜백을 공유한다.
    @MainActor
    public static func makeCreateCollectionView(
        createCollectionUseCase: CreateCollectionUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = CreateCollectionViewModel(
            createCollectionUseCase: createCollectionUseCase,
            logger: logger
        )
        return CreateCollectionView(
            viewModel: viewModel,
            searchNovelUseCase: searchNovelUseCase,
            loadMyLibraryUseCase: loadMyLibraryUseCase,
            logger: logger,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// - Parameters:
    ///   - userID: `fetchCollections`(내 목록)가 명시적으로 요구한다 — `ProfileDomain`의 `.me` 타깃처럼
    ///     로그인 사용자를 알아서 가리키는 계약이 아니다(`CollectionDomain/CLAUDE.md` 참고). 좋아요한
    ///     목록은 세션 토큰 기준이라 이 값이 필요 없다.
    ///   - createCollectionUseCase/searchNovelUseCase/loadMyLibraryUseCase: "내 컬렉션" 탭의 "컬렉션
    ///     만들기"가 로컬 push하는 `CreateCollectionView`(및 그 하위 "작품 추가"/"서재에서 추가")가
    ///     필요로 하는 UseCase — `makeCreateCollectionView`와 동일하게 그대로 관통시킨다.
    ///   - loadCollectionDetailUseCase/collectionLikeUseCase/deleteCollectionUseCase: 카드 탭이 로컬
    ///     push하는 `CollectionDetailView`가 필요로 하는 UseCase — 위 3종과 같은 이유로 그대로 관통시킨다.
    @MainActor
    public static func makeCollectionListView(
        userID: UserID,
        loadCollectionsUseCase: LoadCollectionsUseCase,
        loadLikedCollectionsUseCase: LoadLikedCollectionsUseCase,
        createCollectionUseCase: CreateCollectionUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        collectionLikeUseCase: CollectionLikeUseCase,
        deleteCollectionUseCase: DeleteCollectionUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = CollectionListViewModel(
            userID: userID,
            loadCollectionsUseCase: loadCollectionsUseCase,
            loadLikedCollectionsUseCase: loadLikedCollectionsUseCase,
            logger: logger
        )
        return CollectionListView(
            viewModel: viewModel,
            createCollectionUseCase: createCollectionUseCase,
            searchNovelUseCase: searchNovelUseCase,
            loadMyLibraryUseCase: loadMyLibraryUseCase,
            loadCollectionDetailUseCase: loadCollectionDetailUseCase,
            collectionLikeUseCase: collectionLikeUseCase,
            deleteCollectionUseCase: deleteCollectionUseCase,
            logger: logger,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// - Parameters:
    ///   - id: 조회할 컬렉션. `CollectionListView`의 카드 탭에서 넘어온다.
    ///   - deleteCollectionUseCase: 우상단 더보기(소유자에게만 노출)의 "컬렉션 삭제".
    @MainActor
    public static func makeCollectionDetailView(
        id: CollectionID,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        collectionLikeUseCase: CollectionLikeUseCase,
        deleteCollectionUseCase: DeleteCollectionUseCase,
        logger: Logger? = nil
    ) -> some View {
        CollectionDetailView(
            viewModel: CollectionDetailViewModel(
                id: id,
                loadCollectionDetailUseCase: loadCollectionDetailUseCase,
                collectionLikeUseCase: collectionLikeUseCase,
                deleteCollectionUseCase: deleteCollectionUseCase,
                logger: logger
            ),
            logger: logger
        )
    }
}
