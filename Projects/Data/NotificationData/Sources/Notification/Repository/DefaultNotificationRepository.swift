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
    private let notificationService: NotificationService
    
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
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
            let response = try await notificationService.getNotifications(query)
            return NotificationMapper.pagedNotifications(from: response)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func loadNotificationDetail(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        do {
            let response = try await notificationService.getNotificationDetail(notificationId: id.value)
            return NotificationMapper.notificationDetail(from: response)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func markAsRead(id: NotificationID) async throws(RepositoryError) {
        do {
            try await notificationService.postNotificationRead(notificationId: id.value)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func loadUnreadNotificationStatus() async throws(RepositoryError) -> UnreadNotificationStatus {
        do {
            let response = try await notificationService.getNotificationUnreadStatus()
            return NotificationMapper.unreadNotificationStatus(from: response)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
}
