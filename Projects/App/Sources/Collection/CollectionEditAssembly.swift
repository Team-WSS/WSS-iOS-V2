//
//  CollectionEditAssembly.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import CollectionFeature
import NovelDomain
import SearchDomain

/// 컬렉션 **수정 트리**(수정 → "작품 추가" 검색 → "서재에서 추가") 조립 — 원래 `MypageRootView`에만
/// 있었으나, 딥링크(#228)로 어느 탭에서든 "내" 컬렉션 상세가 열릴 수 있게 되면서 홈/피드/서재도 같은
/// 트리가 필요해져 공용으로 뽑았다(`CollectionDetailAssembly`와 같은 이유 — 2번째 이상의 탭이 같은
/// 목적지를 필요로 한 시점에 뽑는 패턴).
///
/// 각 탭 Root가 여전히 직접 갖는 것: `Destination` 3케이스(`editCollection`/`searchNovelForCollection`/
/// `myLibrarySelectForCollection`), 확정 결과를 수정 화면에 돌려주는 `pendingCollectionNovelSelection`
/// `@State`, 그리고 `path`를 만지는 pop 핸들러(검색 확정 1단계·서재 확정 2단계 —
/// `CollectionFeature/CLAUDE.md` "2단계 pop" 정본). 이 헬퍼는 그 사이의 UseCase 조립만 맡는다.
@MainActor
enum CollectionEditAssembly {
    static func makeEditView(
        id: CollectionID,
        dependencies: AppDependencies,
        pendingNovelSelection: Binding<[CollectionNovel]?>,
        onAddNovelTapped: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        CollectionFeatureFactory.makeEditCollectionView(
            id: id,
            updateCollectionUseCase: DefaultUpdateCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            logger: dependencies.logger,
            pendingNovelSelection: pendingNovelSelection,
            onAddNovelTapped: onAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    static func makeSearchNovelView(
        initialSelection: [CollectionNovel],
        dependencies: AppDependencies,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onLibrarySelectTapped: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        CollectionFeatureFactory.makeSearchNovelView(
            initialSelection: initialSelection,
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            logger: dependencies.logger,
            onConfirm: onConfirm,
            onLibrarySelectTapped: onLibrarySelectTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    static func makeMyLibrarySelectView(
        initialSelection: [CollectionNovel],
        dependencies: AppDependencies,
        onConfirm: @escaping ([CollectionNovel]) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        CollectionFeatureFactory.makeMyLibrarySelectView(
            initialSelection: initialSelection,
            loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                novelRepository: dependencies.novelRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            logger: dependencies.logger,
            onConfirm: onConfirm,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
