//
//  NovelPublicationStatus+Library.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

extension NovelPublicationStatus {
    /// 서재 화면 카피 — 칩·시트에서 공용. (WSSComponent DomainPresentation 승격은 허락 필요라 Feature-local)
    var libraryDisplayName: String {
        switch self {
        case .onGoing:   "연재중"
        case .completed: "완결작"
        }
    }
}
