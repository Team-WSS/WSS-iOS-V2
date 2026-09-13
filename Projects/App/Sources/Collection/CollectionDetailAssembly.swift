//
//  CollectionDetailAssembly.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseData
import BaseDomain
import CollectionDomain
import CollectionFeature

/// 컬렉션 상세(`CollectionFeatureFactory.makeCollectionDetailView`) 조립 — 마이페이지의 "내 컬렉션"
/// 목록뿐 아니라 홈/피드/서재/My 4탭의 타유저 프로필(`UserPageAssembly`) 컬렉션 미리보기도 같은 화면을
/// 공유해서(#201 후속) `NovelDetailAssembly`/`NovelReviewAssembly`와 같은 이유로 공용으로 뽑았다.
///
/// 화면 전환은 `onRoute`(`CollectionDetailRoute` exhaustive switch, #253) 하나로 받는다 — 예전의
/// `onEditTapped` 기본값 no-op은 딥링크(#228) 도입 직후 "수정" 메뉴가 죽은 버튼이 되는 사고를 만든
/// 전례가 있어(4탭 전부 수정 트리를 갖게 되며 해소), 이제 모든 호출자가 `.editCollection` 매핑을
/// 명시해야 컴파일된다.
@MainActor
enum CollectionDetailAssembly {
    static func makeView(
        id: CollectionID,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void,
        onRoute: @escaping (CollectionDetailRoute) -> Void
    ) -> some View {
        CollectionFeatureFactory.makeCollectionDetailView(
            id: id,
            loadCollectionDetailUseCase: DefaultLoadCollectionDetailUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            collectionLikeUseCase: DefaultCollectionLikeUseCase(collectionRepository: dependencies.collectionRepository),
            deleteCollectionUseCase: DefaultDeleteCollectionUseCase(collectionRepository: dependencies.collectionRepository),
            logger: dependencies.logger,
            analyticsTracker: dependencies.analyticsTracker,
            onAuthenticationRequired: onAuthenticationRequired,
            onRoute: onRoute,
            kakaoCollectionShareTemplateID1: NetworkingConfig.kakaoCollectionShareTemplateID1,
            kakaoCollectionShareTemplateID2: NetworkingConfig.kakaoCollectionShareTemplateID2,
            kakaoCollectionShareTemplateID3: NetworkingConfig.kakaoCollectionShareTemplateID3
        )
    }
}
