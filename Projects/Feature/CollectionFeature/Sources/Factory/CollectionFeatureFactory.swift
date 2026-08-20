//
//  CollectionFeatureFactory.swift
//  CollectionFeature
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import CollectionDomain
import Logger

/// 모듈의 유일한 public 진입점. 화면이 둘 이상(생성/상세/리스트 등, #191 이슈 범위)일 예정이라
/// 대표 `makeView` 대신 화면마다 `make<Screen>View`로 짓는다.
public enum CollectionFeatureFactory {

    /// - Parameters:
    ///   - onAddNovelTapped: "작품 추가"/"작품 수정" 타일 진입 콜백 — 작품 검색 화면은 이번 범위 밖(후속
    ///     이슈)이라 호출자가 당장은 placeholder로 받는다.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeCreateCollectionView(
        createCollectionUseCase: CreateCollectionUseCase,
        logger: Logger? = nil,
        onAddNovelTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        let viewModel = CreateCollectionViewModel(
            createCollectionUseCase: createCollectionUseCase,
            logger: logger
        )
        return CreateCollectionView(
            viewModel: viewModel,
            onAddNovelTapped: onAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
