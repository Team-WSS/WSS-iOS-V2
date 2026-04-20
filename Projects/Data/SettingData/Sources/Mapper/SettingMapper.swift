//
//  SettingMapper.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//

import Foundation
import BaseData
import SettingDomain

enum SettingMapper {
    
    // MARK: - DTO -> Entity
    
    static func appUpdatePolicy(
        from response: AppMinimumVersionResponse
    ) throws -> AppUpdatePolicy {
        AppUpdatePolicy(
            minimumVersion: try appVersion(from: response.minimumVersion),
            updateDate: try updateDate(from: response.updateDate)
        )
    }

    static func termsAgreementDraft(
        from response: TermSettingResponse
    ) -> TermsAgreementDraft {
        TermsAgreementDraft(
            initial: [
                .serviceAgreement: response.serviceAgreed,
                .privacyPolicy: response.privacyAgreed,
                .marketingConsent: response.marketingAgreed
            ]
        )
    }

    // MARK: - Entity -> DTO
    
    static func termSettingRequest(
        from draft: TermsAgreementDraft
    ) -> TermSettingRequest {
        TermSettingRequest(
            serviceAgreed: draft.isAgreed(.serviceAgreement),
            privacyAgreed: draft.isAgreed(.privacyPolicy),
            marketingAgreed: draft.isAgreed(.marketingConsent)
        )
    }
}

private extension SettingMapper {
    static func appVersion(
        from text: String
    ) throws -> AppVersion {
        do {
            return try AppVersion(text)
        } catch {
            let type = ConversionType.appVersion
            throw MappingError.invalidConversion(type: type.description, value: text)
        }
    }

    static func updateDate(
        from text: String
    ) throws -> Date {
        guard let date = DateParser.date(from: text) else {
            let type = ConversionType.updateDate
            throw MappingError.invalidConversion(type: type.description, value: text)
        }

        return date
    }
}
