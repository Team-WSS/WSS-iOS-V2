//
//  CollectionListAssembly.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import CollectionFeature

/// 컬렉션 목록(`CollectionFeatureFactory.makeCollectionListView`) 조립 — 마이페이지의 "내 컬렉션"
/// 목록뿐 아니라 홈/피드/서재/My 4탭의 타유저 프로필(`UserPageAssembly`) 컬렉션 헤더 탭도 같은 화면을
/// 공유해서(#201 후속) `CollectionDetailAssembly`와 같은 이유로 공용으로 뽑았다.
///
/// `isOwnCollections: false`(기본값)는 남의 컬렉션을 보는 자리다 — 세그먼트 탭("좋아요한 컬렉션"이
/// 세션 토큰=로그인 사용자 자신 기준이라 재사용 불가)과 "컬렉션 만들기"를 숨기고 "내 컬렉션"(`userID`
/// 기준) 콘텐츠만 보여준다. **자기 컬렉션을 다루는 마이페이지만 `isOwnCollections: true`로 명시 호출**
/// 해야 세그먼트 탭·생성 버튼이 보인다.
@MainActor
enum CollectionListAssembly {
    static func makeView(
        userID: UserID,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void,
        onCollectionSelected: @escaping (CollectionID) -> Void,
        onCreateTapped: @escaping () -> Void = {},
        isOwnCollections: Bool = false
    ) -> some View {
        CollectionFeatureFactory.makeCollectionListView(
            userID: userID,
            loadCollectionsUseCase: DefaultLoadCollectionsUseCase(collectionRepository: dependencies.collectionRepository),
            loadLikedCollectionsUseCase: DefaultLoadLikedCollectionsUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onCreateTapped: onCreateTapped,
            onCollectionSelected: onCollectionSelected,
            isOwnCollections: isOwnCollections
        )
    }
}
