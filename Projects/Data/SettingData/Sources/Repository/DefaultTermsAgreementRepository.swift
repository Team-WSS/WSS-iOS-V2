//
//  DefaultTermsAgreementRepository.swift
//  SettingData
//
//  Created by YunhakLee on 5/20/26.
//

import BaseData
import BaseDomain
import Networking
import SettingDomain

public struct DefaultTermsAgreementRepository: TermsAgreementRepository {
    private let service: SettingService
    private let logger: DataLogger?

    init(
        settingService: SettingService,
        logger: DataLogger? = nil
    ) {
        self.service = settingService
        self.logger = logger
    }

    public func loadTermsAgreementDraft() async throws(RepositoryError) -> TermsAgreementDraft {
        let action = SettingAction.loadTermsAgreementDraft

        do {
            let response = try await service.getTermSetting()
            let draft = SettingMapper.termsAgreementDraft(from: response)
            logger?.logSuccess(action: action.text)
            return draft
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }

    public func save(draft: TermsAgreementDraft) async throws(RepositoryError) {
        let action = SettingAction.saveTermsAgreementDraft

        do {
            let request = SettingMapper.termSettingRequest(from: draft)
            try await service.patchTermSetting(request)
            logger?.logSuccess(action: action.text)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.text, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.text, error: error)
            throw .unknown
        }
    }
}
