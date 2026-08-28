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
/// **화면 간 이동은 전부 App이 조립한다**(#201부터 — "작품 추가"/"서재에서 추가"처럼 다른 화면의
/// draft를 채우는 값 선택기까지 포함해 예외 없이 App으로 옮겼다, 사용자 확정). 이 모듈 안에는
/// `navigationDestination`이 없다.
public enum CollectionFeatureFactory {

    /// - Parameters:
    ///   - pendingNovelSelection: "작품 추가" 화면(App이 push)이 확정한 결과를 돌려받는 통로 —
    ///     `nil→값` 전이로 감지하는 1회성 신호(`OnboardingFeature`의 확정 신호 패턴과 동일). 이 화면이
    ///     소비 즉시 다시 `nil`로 되돌린다. 호출자(App)는 "작품 추가" 화면이 확정될 때 이 Binding에
    ///     결과를 채우고 그만큼 pop하면 된다(`onAddNovelTapped` 문서 참고).
    ///   - onAddNovelTapped: "작품 추가" 타일 탭 콜백. 현재 선택된 작품 목록을 실어 올린다(그 화면이
    ///     이미 담긴 작품도 선택된 채로 보여주는 편집 화면이라서). 실제 화면 전환
    ///     (`makeSearchNovelView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeCreateCollectionView(
        createCollectionUseCase: CreateCollectionUseCase,
        logger: Logger? = nil,
        pendingNovelSelection: Binding<[CollectionNovel]?>,
        onAddNovelTapped: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = CreateCollectionViewModel(
            mode: .create,
            createCollectionUseCase: createCollectionUseCase,
            logger: logger
        )
        return CreateCollectionView(
            viewModel: viewModel,
            pendingNovelSelection: pendingNovelSelection,
            onAddNovelTapped: onAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// "컬렉션 수정" 화면 — `CreateCollectionView`를 수정 모드로 재사용한다. `id`로 대상 컬렉션을
    /// 화면이 뜨자마자 자기 스스로 불러와(`.load`) draft를 채운다(호출자가 미리 데이터를 준비해 넘길
    /// 필요가 없다 — `FeedFeature.CreateFeedViewModel.loadForEdit`와 동일 패턴). 나머지 파라미터는
    /// `makeCreateCollectionView`와 동일한 위상.
    @MainActor
    public static func makeEditCollectionView(
        id: CollectionID,
        updateCollectionUseCase: UpdateCollectionUseCase,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        logger: Logger? = nil,
        pendingNovelSelection: Binding<[CollectionNovel]?>,
        onAddNovelTapped: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = CreateCollectionViewModel(
            mode: .edit(id),
            updateCollectionUseCase: updateCollectionUseCase,
            loadCollectionDetailUseCase: loadCollectionDetailUseCase,
            logger: logger
        )
        return CreateCollectionView(
            viewModel: viewModel,
            pendingNovelSelection: pendingNovelSelection,
            onAddNovelTapped: onAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// "작품 추가" 화면 — 검색해서 다중선택한 결과를 확정하면 호출자(App)가 그 결과를
    /// `makeCreateCollectionView`의 `pendingNovelSelection`에 채워 `CreateCollectionView`까지 pop한다.
    ///
    /// - Parameters:
    ///   - initialSelection: 진입 시점에 이미 선택돼 있던 작품 목록(`CreateCollectionView`가 현재
    ///     draft 기준으로 넘긴다) — 이 화면은 처음부터 그 상태로 보여준다.
    ///   - onConfirm: "완료" 확정 콜백. 이 화면 자신은 dismiss()하지 않는다 — 호출자(App)가 받아서
    ///     `CreateCollectionView`까지 pop한다.
    ///   - onLibrarySelectTapped: "서재에서 추가" 탭 콜백. 현재까지 선택된 목록을 실어 올린다. 실제
    ///     화면 전환(`makeMyLibrarySelectView` 조립)은 호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeSearchNovelView(
        initialSelection: [CollectionNovel],
        searchNovelUseCase: SearchNovelUseCase,
        logger: Logger? = nil,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onLibrarySelectTapped: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        CollectionSearchNovelView(
            viewModel: CollectionSearchNovelViewModel(
                initialSelection: initialSelection,
                searchNovelUseCase: searchNovelUseCase,
                logger: logger
            ),
            onConfirm: onConfirm,
            onLibrarySelectTapped: onLibrarySelectTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// "서재에서 추가" 화면 — 내 서재를 다중선택 후 "추가"로 확정하면 호출자(App)가 그 결과를
    /// `makeCreateCollectionView`의 `pendingNovelSelection`에 채워 `CreateCollectionView`까지 pop한다
    /// (`makeSearchNovelView`를 거쳐 두 단계 push된 상태이므로 App은 그만큼 더 pop해야 한다).
    ///
    /// - Parameter onConfirm: "추가" 확정 콜백. 이 화면 자신은 dismiss()하지 않는다.
    @MainActor
    public static func makeMyLibrarySelectView(
        initialSelection: [CollectionNovel],
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        logger: Logger? = nil,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        CollectionMyLibrarySelectView(
            viewModel: CollectionMyLibrarySelectViewModel(
                initialSelection: initialSelection,
                loadMyLibraryUseCase: loadMyLibraryUseCase,
                logger: logger
            ),
            onConfirm: onConfirm,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// - Parameters:
    ///   - userID: `fetchCollections`(내 목록)가 명시적으로 요구한다 — `ProfileDomain`의 `.me` 타깃처럼
    ///     로그인 사용자를 알아서 가리키는 계약이 아니다(`CollectionDomain/CLAUDE.md` 참고). 좋아요한
    ///     목록은 세션 토큰 기준이라 이 값이 필요 없다.
    ///   - onCreateTapped: "컬렉션 만들기" 버튼 탭 콜백. 실제 화면 전환(`makeCreateCollectionView`
    ///     조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - onCollectionSelected: 카드 탭 → 컬렉션 상세 진입 콜백. 실제 화면 전환
    ///     (`makeCollectionDetailView` 조립)은 호출자(App 조정 계층)가 수행한다.
    ///   - isOwnCollections: `false`면 남의 컬렉션을 보는 자리다(타유저 프로필의 "컬렉션" 헤더 탭) —
    ///     세그먼트 탭·"컬렉션 만들기"를 숨기고 "내 컬렉션"(`userID` 기준) 콘텐츠만 보여준다.
    ///     "좋아요한 컬렉션" 탭은 세션 토큰=로그인 사용자 자신 기준이라 타유저 페이지에 재사용할 수
    ///     없다(`CollectionFeature/CLAUDE.md` 참고). 이 모드에선 `loadLikedCollectionsUseCase`는
    ///     실제로 호출되지 않지만(세그먼트 탭이 없어 그 탭으로 전환할 방법이 없음) `CollectionListViewModel`
    ///     생성자가 여전히 요구하므로 호출자가 채워야 한다.
    @MainActor
    public static func makeCollectionListView(
        userID: UserID,
        loadCollectionsUseCase: LoadCollectionsUseCase,
        loadLikedCollectionsUseCase: LoadLikedCollectionsUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void,
        onCreateTapped: @escaping () -> Void,
        onCollectionSelected: @escaping (CollectionID) -> Void,
        isOwnCollections: Bool = true
    ) -> some View {
        let viewModel = CollectionListViewModel(
            userID: userID,
            loadCollectionsUseCase: loadCollectionsUseCase,
            loadLikedCollectionsUseCase: loadLikedCollectionsUseCase,
            logger: logger
        )
        return CollectionListView(
            viewModel: viewModel,
            onAuthenticationRequired: onAuthenticationRequired,
            onCreateTapped: onCreateTapped,
            onCollectionSelected: onCollectionSelected,
            isOwnCollections: isOwnCollections
        )
    }

    /// - Parameters:
    ///   - id: 조회할 컬렉션. `CollectionListView`의 카드 탭에서 넘어온다.
    ///   - deleteCollectionUseCase: 우상단 더보기(소유자에게만 노출)의 "컬렉션 삭제".
    ///   - onAuthenticationRequired: 이 화면 자신의 서버 호출이 인증 만료를 만날 수 있어 받는다.
    ///   - onNovelTapped: 작품 그리드 셀 탭 → 작품 상세(`NovelDetailFeature`) 진입 콜백. Feature 모듈끼리
    ///     서로 import 못 해 이 화면이 직접 만들 수 없다 — 실제 화면 전환은 호출자(App)가 수행한다.
    ///   - onEditTapped: 더보기 "컬렉션 수정" 탭 콜백. 실제 화면 전환(`makeEditCollectionView` 조립)은
    ///     호출자(App 조정 계층)가 수행한다 — 그 화면이 `id`로 대상을 스스로 다시 불러오므로(자기 로드
    ///     방식) 이 콜백은 파라미터가 필요 없다.
    @MainActor
    public static func makeCollectionDetailView(
        id: CollectionID,
        loadCollectionDetailUseCase: LoadCollectionDetailUseCase,
        collectionLikeUseCase: CollectionLikeUseCase,
        deleteCollectionUseCase: DeleteCollectionUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditTapped: @escaping () -> Void
    ) -> some View {
        CollectionDetailView(
            viewModel: CollectionDetailViewModel(
                id: id,
                loadCollectionDetailUseCase: loadCollectionDetailUseCase,
                collectionLikeUseCase: collectionLikeUseCase,
                deleteCollectionUseCase: deleteCollectionUseCase,
                logger: logger
            ),
            onAuthenticationRequired: onAuthenticationRequired,
            onNovelTapped: onNovelTapped,
            onEditTapped: onEditTapped
        )
    }
}
