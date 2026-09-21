//
//  DefaultNovelNotificationRepository.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import NotificationDomain
import BaseDomain
import BaseData
import Networking

struct DefaultNovelNotificationRepository: NovelNotificationRepository {
    private let service: NovelNotificationService
    private let logger: DataLogger?

    init(
        novelNotificationService: NovelNotificationService,
        logger: DataLogger?
    ) {
        self.service = novelNotificationService
        self.logger = logger
    }

    public func loadSubscriptions(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        let action = NovelNotificationAction.loadSubscriptions

        do {
            let query = NovelNotificationSubscriptionsQuery(
                notificationType: NovelNotificationMapper.serverValue(for: type),
                lastSubscriptionId: lastSubscriptionID?.value ?? 0,
                size: size
            )
            let response = try await service.getSubscriptions(query)
            let result = NovelNotificationMapper.pagedSubscriptions(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func deleteSubscriptions(
        type: NovelNotificationType,
        novelIDs: [NovelID]
    ) async throws(RepositoryError) {
        let action = NovelNotificationAction.deleteSubscriptions

        do {
            let request = NovelNotificationUnsubscribeRequest(
                notificationType: NovelNotificationMapper.serverValue(for: type),
                novelIds: novelIDs.map(\.value)
            )
            try await service.deleteSubscriptions(request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        let action = NovelNotificationAction.loadSetting

        do {
            let response = try await service.getNotificationSetting(novelID: novelID.value)
            let result = NovelNotificationMapper.setting(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError) {
        let action = NovelNotificationAction.updateSetting

        do {
            let request = NovelNotificationMapper.request(from: setting)
            try await service.putNotificationSetting(novelID: novelID.value, request: request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
