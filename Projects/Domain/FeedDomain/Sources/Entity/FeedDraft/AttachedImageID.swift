//
//  AttachedImageID.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 6/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// `FeedDraft.attachedImages`의 원소 식별자.
///
/// 작성 도중 클라이언트에서만 사용된다. 서버 전송 시점에는
/// Feature 레이어가 이 ID에 매핑된 실제 이미지 Data를 multipart로 보낸다.
public struct AttachedImageID: Hashable {
    public let value: UUID

    public init(value: UUID = UUID()) {
        self.value = value
    }
}
