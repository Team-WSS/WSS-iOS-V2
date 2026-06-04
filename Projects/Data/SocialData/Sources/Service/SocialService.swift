//
//  SocialService.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

protocol SocialService {
    func postBlockUser(_ query: BlockUserQuery) async throws
    func deleteBlock(blockID: Int) async throws
    func getBlockedUsers() async throws -> BlockedUserResponse
    func postReportSpoilerFeed(feedID: Int) async throws
    func postReportImproperFeed(feedID: Int) async throws
    func postReportSpoilerComment(feedID: Int, commentID: Int) async throws
    func postReportImproperComment(feedID: Int, commentID: Int) async throws
}
