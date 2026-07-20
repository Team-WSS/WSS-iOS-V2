//
//  SearchFactory.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import RecommendationDomain
import Logger

/// 모듈의 유일한 public 진입점.
public enum SearchFactory {

    @MainActor
    public static func makeView(
        loadSosoPickUseCase: LoadSosoPickUseCase,
        logger: Logger? = nil
    ) -> some View {
        NormalSearchView(
            viewModel: NormalSearchViewModel(
                loadSosoPickUseCase: loadSosoPickUseCase,
                logger: logger
            )
        )
    }
}
