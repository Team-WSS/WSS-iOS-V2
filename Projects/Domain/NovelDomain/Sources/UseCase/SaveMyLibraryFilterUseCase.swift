//
//  SaveMyLibraryFilterUseCase.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 현재 내 서재 필터·정렬을 저장해 다음 앱 실행에서 복원되게 한다(#221).
///
/// best-effort 로컬 저장이라 `throws`가 없다 — 필터·정렬이 바뀔 때마다 ViewModel이 부른다.
public protocol SaveMyLibraryFilterUseCase: Sendable {
    func execute(_ filter: MyLibraryFilter)
}

public final class DefaultSaveMyLibraryFilterUseCase: SaveMyLibraryFilterUseCase {

    private let repository: MyLibraryFilterRepository

    public init(repository: MyLibraryFilterRepository) {
        self.repository = repository
    }

    public func execute(_ filter: MyLibraryFilter) {
        repository.saveFilter(filter)
    }
}
