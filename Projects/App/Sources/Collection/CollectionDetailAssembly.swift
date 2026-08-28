//
//  CollectionDetailAssembly.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import CollectionFeature

/// 컬렉션 상세(`CollectionFeatureFactory.makeCollectionDetailView`) 조립 — 마이페이지의 "내 컬렉션"
/// 목록뿐 아니라 홈/피드/서재/My 4탭의 타유저 프로필(`UserPageAssembly`) 컬렉션 미리보기도 같은 화면을
/// 공유해서(#201 후속) `NovelDetailAssembly`/`NovelReviewAssembly`와 같은 이유로 공용으로 뽑았다.
///
/// `onEditTapped`는 소유자(`detail.isMine == true`)에게만 노출되는 "컬렉션 수정" 진입 콜백이라 기본값을
/// no-op으로 둔다 — 타유저 프로필에서 열리는 컬렉션은 항상 남의 것이라(`isMine == false`) 그 버튼
/// 자체가 안 뜨므로 이 콜백이 호출될 일이 없다. 자기 컬렉션 편집이 필요한 마이페이지만 실제로 채운다.
@MainActor
enum CollectionDetailAssembly {
    static func makeView(
        id: CollectionID,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditTapped: @escaping () -> Void = {}
    ) -> some View {
        CollectionFeatureFactory.makeCollectionDetailView(
            id: id,
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            collectionLikeUseCase: DefaultCollectionLikeUseCase(collectionRepository: dependencies.collectionRepository),
            deleteCollectionUseCase: DefaultDeleteCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onNovelTapped: onNovelTapped,
            onEditTapped: onEditTapped
        )
    }
}
