//
//  NovelReviewFactory.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import Logger
import NovelReviewDomain

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 `internal`로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum NovelReviewFactory {

    /// - Parameter title: 네비게이션 타이틀. 이 화면은 네비게이션으로만 진입하므로,
    ///   표시할 제목은 **진입 이전 화면이 알고 있는 값**을 주입한다.
    @MainActor
    public static func makeView(
        novelID: NovelID,
        title: String,
        loadUseCase: LoadNovelReviewDraftUseCase,
        saveUseCase: SaveNovelReviewUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = NovelReviewViewModel(
            novelID: novelID,
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            logger: logger
        )
        return NovelReviewView(viewModel: viewModel, title: title)
    }
}
