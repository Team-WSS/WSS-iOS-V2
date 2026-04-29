//
//  DefaultNotificationRepository.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NotificationDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultNotificationRepository: NotificationRepository {
    private let service: NotificationService
    private let logger: DataLogger?

    init(
        notificationService: NotificationService,
        logger: DataLogger?
    ) {
        self.service = notificationService
        self.logger = logger
    }

    public func loadNotifications(
        lastNotificationID: NotificationID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNotifications {
        do {
            let query = NotificationQeury(
                lastNotificationId: lastNotificationID?.value ?? 0,
                size: size
            )
            let response = try await service.getNotifications(query)
            let result = NotificationMapper.pagedNotifications(from: response)
            logger?.logSuccess(action: "loadNotifications")
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "loadNotifications", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "loadNotifications", error: error)
            throw .unknown
        }
    }

    public func loadNotificationDetail(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        do {
            let response = try await service.getNotificationDetail(notificationId: id.value)
            let result = NotificationMapper.notificationDetail(from: response)
            logger?.logSuccess(action: "loadDetail")
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "loadDetail", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "loadDetail", error: error)
            throw .unknown
        }
    }

    public func markAsRead(id: NotificationID) async throws(RepositoryError) {
        do {
            try await service.postNotificationRead(notificationId: id.value)
            logger?.logSuccess(action: "markAsRead")
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "markAsRead", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "markAsRead", error: error)
            throw .unknown
        }
    }

    public func loadUnreadNotificationStatus() async throws(RepositoryError) -> UnreadNotificationStatus {
        do {
            let response = try await service.getNotificationUnreadStatus()
            let result = NotificationMapper.unreadNotificationStatus(from: response)
            logger?.logSuccess(action: "loadUnreadStatus")
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: "loadUnreadStatus", error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: "loadUnreadStatus", error: error)
            throw .unknown
        }
    }
}
