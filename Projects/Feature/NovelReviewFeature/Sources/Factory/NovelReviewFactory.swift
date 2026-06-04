//
//  NovelReviewFactory.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 `internal`로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// App(DI)·Demo는 이 Factory만 사용한다.
public enum NovelReviewFactory {

    @MainActor
    public static func makeView(novelID: NovelID) -> some View {
        let viewModel = DefaultNovelReviewViewModel(novelID: novelID)
        return NovelReviewView(viewModel: viewModel)
    }
}
