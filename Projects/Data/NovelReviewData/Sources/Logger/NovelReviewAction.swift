//
//  NovelReviewAction.swift
//  NovelReviewData
//
//  Created by Codex on 4/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum NovelReviewAction {
    case load
    case post
    case put
    case delete

    var name: String {
        switch self {
        case .load:
            return "load"
        case .post:
            return "post"
        case .put:
            return "put"
        case .delete:
            return "delete"
        }
    }
}
