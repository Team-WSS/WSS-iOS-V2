//
//  Author.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Author: Sendable {

    public let userId: UserID?
    public let nickname: String
    public let profileImage: URL?

    /// 서버가 탈퇴한 유저를 가리킬 때 `userId` 자리에 내려주는 센티널 값(피드 관련 응답 실측 —
    /// `TotalFeedResponse`/`FeedDetailResponse`/`NovelFeedResponse` 전부 `userId: Int`가 non-optional
    /// 이라 서버가 항상 값을 채우는데, 탈퇴 유저는 이 값이 -1로 온다). `UserID`(`IDWrapper<Int>`)를
    /// 직접 확장하지 않는 이유: `FeedID`/`NovelID` 등 다른 ID 래퍼도 전부 같은 `IDWrapper<Int>`
    /// typealias라 그쪽까지 `.withdrawn`이 새어버린다 — `Author` 전용으로 가둔다.
    private static let withdrawnUserID = UserID(-1)

    /// 실제로 프로필 화면으로 이동 가능한 유저 ID. `userId`가 없거나(응답 미제공) 탈퇴 유저(센티널
    /// -1)를 가리키면 nil — 호출부 입장에선 "이동할 프로필이 없다"는 같은 의미라 구분할 이유가 없다.
    public var accessibleUserId: UserID? {
        guard let userId, userId != Self.withdrawnUserID else { return nil }
        return userId
    }

    public init(
        userId: UserID? = nil,
        nickname: String,
        profileImage: URL?
    ) {
        self.userId = userId
        self.nickname = nickname
        self.profileImage = profileImage
    }
}
