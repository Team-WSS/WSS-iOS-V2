//
//  CommentAction.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Logger

public enum CommentAction {
    case fetchComments
    case postComment
    case patchComment
    case deleteComment

    var name: String {
        switch self {
        case .fetchComments:    "전체 댓글 조회"
        case .postComment:      "댓글 작성"
        case .patchComment:     "댓글 수정"
        case .deleteComment:    "댓글 삭제"
        }
    }
}
