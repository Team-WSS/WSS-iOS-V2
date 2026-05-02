//
//  DefaultAppUpdateRepository.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//

import Networking
import BaseData
import BaseDomain
import SettingDomain

public struct DefaultAppUpdateRepository: AppUpdateRepository {
    private let service: SettingService
    private let logger: DataLogger?

    init(
        settingService: SettingService,
        logger: DataLogger? = nil
    ) {
        self.service = settingService
        self.logger = logger
    }

    public func loadAppUpdatePolicy() async throws(RepositoryError) -> AppUpdatePolicy {
        let action = SettingAction.loadAppUpdatePolicy
        
        do {
            let response = try await service.getAppMinimumVersion()
            let policy = try SettingMapper.appUpdatePolicy(from: response)
            logger?.logSuccess(action: action.name)
            return policy
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch let error as MappingError {
            logger?.logMappingError(action: action.name, error: error)
            throw .invalidData
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
