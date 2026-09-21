//
//  NovelPublicationStatus+Search.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

extension NovelPublicationStatus {
    /// 상세탐색 필터 화면 카피. (WSSComponent DomainPresentation 승격은 허락 필요라 Feature-local,
    /// `LibraryFeature`의 `NovelPublicationStatus+Library.libraryDisplayName`과 같은 텍스트지만
    /// 별개 확장 — 화면별로 각자 소유한다.)
    var searchDisplayName: String {
        switch self {
        case .onGoing:   "연재중"
        case .completed: "완결작"
        }
    }
}
