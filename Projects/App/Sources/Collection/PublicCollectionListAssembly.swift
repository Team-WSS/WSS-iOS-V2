//
//  PublicCollectionListAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import CollectionFeature

/// 전체 컬렉션뷰("컬렉션 모음.zip", `CollectionFeatureFactory.makePublicCollectionListView`) 조립 —
/// 지금 진입점은 홈 컬렉션 섹션 제목 하나뿐이다(#283).
@MainActor
enum PublicCollectionListAssembly {
    static func makeView(
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void,
        onRoute: @escaping (PublicCollectionListRoute) -> Void
    ) -> some View {
        CollectionFeatureFactory.makePublicCollectionListView(
            loadPublicCollectionsUseCase: DefaultLoadPublicCollectionsUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onRoute: onRoute
        )
    }
}
