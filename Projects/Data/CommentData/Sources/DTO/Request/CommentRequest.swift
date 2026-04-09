//
//  CommentRequest.swift
//  CommentData
//
//  Created by Seoyeon Choi on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public struct CommentRequest: RequestBodyConvertible {
    let commentContent: String
}
