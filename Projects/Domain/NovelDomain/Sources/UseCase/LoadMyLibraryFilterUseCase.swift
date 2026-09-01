//
//  LoadMyLibraryFilterUseCase.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 마지막으로 저장된 내 서재 필터·정렬을 복원한다(#221). 없으면 nil(화면은 기본 필터로 시작).
///
/// best-effort 로컬 복원이라 `throws`가 없다 — ViewModel이 `init`에서 동기로 부른다.
public protocol LoadMyLibraryFilterUseCase: Sendable {
    func execute() -> MyLibraryFilter?
}

public final class DefaultLoadMyLibraryFilterUseCase: LoadMyLibraryFilterUseCase {

    private let repository: MyLibraryFilterRepository

    public init(repository: MyLibraryFilterRepository) {
        self.repository = repository
    }

    public func execute() -> MyLibraryFilter? {
        repository.loadFilter()
    }
}
