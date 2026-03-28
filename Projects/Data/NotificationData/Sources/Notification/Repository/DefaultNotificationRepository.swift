//
//  DefaultNotificationRepository.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NotificationDomain
import BaseDomain
import Logger
import Networking

public struct DefaultNotificationRepository: NotificationRepository {
    private let service: NotificationService
    private let logger: NotificationLogger?
    
    init(
        notificationService: NotificationService,
        logger: NotificationLogger?
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
            return NotificationMapper.pagedNotifications(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .loadNotifications, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .loadNotifications, error: error)
            throw .unknown
        }
    }
    
    public func loadNotificationDetail(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        do {
            let response = try await service.getNotificationDetail(notificationId: id.value)
            return NotificationMapper.notificationDetail(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .loadDetail, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .loadDetail, error: error)
            throw .unknown
        }
    }
    
    public func markAsRead(id: NotificationID) async throws(RepositoryError) {
        do {
            try await service.postNotificationRead(notificationId: id.value)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .markAsRead, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .markAsRead, error: error)
            throw .unknown
        }
    }
    
    public func loadUnreadNotificationStatus() async throws(RepositoryError) -> UnreadNotificationStatus {
        do {
            let response = try await service.getNotificationUnreadStatus()
            return NotificationMapper.unreadNotificationStatus(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .loadUnreadStatus, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .loadUnreadStatus, error: error)
            throw .unknown
        }
    }
}
