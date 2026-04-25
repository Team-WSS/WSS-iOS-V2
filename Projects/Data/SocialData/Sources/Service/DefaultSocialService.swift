//
//  DefaultSocialService.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultSocialService: SocialService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func postBlockUser(userID: Int) async throws {
        let endpoint = SocialEndpoint.blockUser(userID: userID)
        _ = try await client.request(endpoint)
    }

    func deleteBlock(blockID: Int) async throws {
        let endpoint = SocialEndpoint.unblockUser(userID: blockID)
        _ = try await client.request(endpoint)
    }

    func getBlockedUsers() async throws -> [BlockedUserResponse] {
        let endpoint = SocialEndpoint.getBlockedUsers
        return try await client.request(endpoint, decodeTo: [BlockedUserResponse].self)
    }

    func postReportSpoilerFeed(feedID: Int) async throws {
        let endpoint = SocialEndpoint.reportSpoilerFeed(feedID: feedID)
        _ = try await client.request(endpoint)
    }

    func postReportImproperFeed(feedID: Int) async throws {
        let endpoint = SocialEndpoint.reportImproperFeed(feedID: feedID)
        _ = try await client.request(endpoint)
    }

    func postReportSpoilerComment(feedID: Int, commentID: Int) async throws {
        let endpoint = SocialEndpoint.reportSpoilerComment(feedID: feedID, commentID: commentID)
        _ = try await client.request(endpoint)
    }

    func postReportImproperComment(feedID: Int, commentID: Int) async throws {
        let endpoint = SocialEndpoint.reportImproperComment(feedID: feedID, commentID: commentID)
        _ = try await client.request(endpoint)
    }
}
