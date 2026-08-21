//
//  CollectionFeatureFactory.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import SearchDomain
import Logger

/// 모듈의 유일한 public 진입점. 화면이 둘 이상(생성/상세/리스트 등, #191 이슈 범위)일 예정이라
/// 대표 `makeView` 대신 화면마다 `make<Screen>View`로 짓는다.
///
/// "작품 추가" 화면(`AddNovelView`)은 이 Factory에 노출되지 않는다 — `CreateCollectionView`가 자기
/// 내부에서만 push하는 로컬 화면이라(`ReadingPeriodSheet`와 같은 위상) 모듈 밖(App/Demo)이 알 이유가
/// 없다. 대신 그 화면이 검색에 쓸 `searchNovelUseCase`만 여기서 받아 내려보낸다.
public enum CollectionFeatureFactory {

    /// - Parameters:
    ///   - searchNovelUseCase: "작품 추가" 화면(내부 로컬 push)의 작품 검색용 — `FeedFeature`의 연결
    ///     작품 검색과 같은 이유로 `SearchDomain`을 쓴다.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다. "작품 추가" 화면도 같은 콜백을 공유한다.
    @MainActor
    public static func makeCreateCollectionView(
        createCollectionUseCase: CreateCollectionUseCase,
        searchNovelUseCase: SearchNovelUseCase,
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
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
