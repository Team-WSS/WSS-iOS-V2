//
//  NovelReviewFeatureFactory.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 `internal`로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum NovelReviewFeatureFactory {

    /// - Parameters:
    ///   - title: 네비게이션 타이틀. 이 화면은 네비게이션으로만 진입하므로,
    ///     표시할 제목은 **진입 이전 화면이 알고 있는 값**을 주입한다.
    ///   - status: 진입 시 읽기 상태 초기값. 이 화면은 항상 읽기 상태가 정해진 채로 진입하므로
    ///     호출자가 주입한다(로드된 초안이 있으면 그 값으로 갱신될 수 있다).
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 로드/저장 등 서버 호출 공통.
    ///     실제 화면 전환은 호출자(App 조정 계층)가 수행한다.
    ///   - keywordSearchSheet: 키워드 탐색 시트 콘텐츠 빌더 — `KeywordFeature`는 이 모듈이 모르므로
    ///     App이 조립해 주입한다(`KeywordSearchSheetBuilder` 참고).
    @MainActor
    public static func makeView(
        novelID: NovelID,
        title: String,
        status: ReadingStatus,
        loadUseCase: LoadNovelReviewDraftUseCase,
        saveUseCase: SaveNovelReviewUseCase,
        logger: Logger? = nil,
        onAuthenticationRequired: @escaping () -> Void,
        keywordSearchSheet: @escaping KeywordSearchSheetBuilder
    ) -> some View {
        let viewModel = NovelReviewViewModel(
            novelID: novelID,
            status: status,
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            logger: logger
        )
        return NovelReviewView(
            viewModel: viewModel,
            title: title,
            onAuthenticationRequired: onAuthenticationRequired,
            keywordSearchSheet: keywordSearchSheet
        )
    }
}
