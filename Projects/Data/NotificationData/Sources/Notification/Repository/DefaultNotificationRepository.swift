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
        let action = NotificationAction.loadNotifications

        do {
            let query = NotificationQeury(
                lastNotificationId: lastNotificationID?.value ?? 0,
                size: size
            )
            let response = try await service.getNotifications(query)
            let result = NotificationMapper.pagedNotifications(from: response)
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

    public func loadNotificationDetail(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        let action = NotificationAction.loadDetail

        do {
            let response = try await service.getNotificationDetail(notificationId: id.value)
            let result = NotificationMapper.notificationDetail(from: response)
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

    public func markAsRead(id: NotificationID) async throws(RepositoryError) {
        let action = NotificationAction.markAsRead

        do {
            try await service.postNotificationRead(notificationId: id.value)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func loadUnreadNotificationStatus() async throws(RepositoryError) -> UnreadNotificationStatus {
        let action = NotificationAction.loadUnreadStatus

        do {
            let response = try await service.getNotificationUnreadStatus()
            let result = NotificationMapper.unreadNotificationStatus(from: response)
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
}
