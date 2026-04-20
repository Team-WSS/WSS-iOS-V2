//
//  SettingMapperTests.swift
//  SettingData
//
//  Created by YunhakLee on 5/20/26.
//

import Foundation
import Testing
@testable import SettingData
import BaseData
import SettingDomain

@Suite("SettingMapper")
struct SettingMapperTests {

    // MARK: - Helpers

    private func makeAppMinimumVersionResponse(
        minimumVersion: String = "1.2.3",
        updateDate: String = "2026-04-20"
    ) -> AppMinimumVersionResponse {
        AppMinimumVersionResponse(
            minimumVersion: minimumVersion,
            updateDate: updateDate
        )
    }

    private func makeTermSettingResponse(
        serviceAgreed: Bool = true,
        privacyAgreed: Bool = false,
        marketingAgreed: Bool = true
    ) -> TermSettingResponse {
        TermSettingResponse(
            serviceAgreed: serviceAgreed,
            privacyAgreed: privacyAgreed,
            marketingAgreed: marketingAgreed
        )
    }

    private func makeDraft(
        serviceAgreed: Bool = false,
        privacyAgreed: Bool = false,
        marketingAgreed: Bool = false
    ) -> TermsAgreementDraft {
        TermsAgreementDraft(
            initial: [
                .serviceAgreement: serviceAgreed,
                .privacyPolicy: privacyAgreed,
                .marketingConsent: marketingAgreed
            ]
        )
    }

    // MARK: - AppUpdatePolicy

    @Test("최소 버전 응답을 AppUpdatePolicy로 변환한다")
    func mapsAppUpdatePolicy() throws {
        let response = makeAppMinimumVersionResponse(
            minimumVersion: "2.5.1",
            updateDate: "2026-04-20"
        )

        let result = try SettingMapper.appUpdatePolicy(from: response)

        #expect(result.minimumVersion == AppVersion(major: 2, minor: 5, patch: 1))
        #expect(result.updateDate == DateParser.date(from: "2026-04-20"))
    }

    @Test("minimumVersion 형식이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenMinimumVersionIsInvalid() async {
        let response = makeAppMinimumVersionResponse(minimumVersion: "1.2.3.4")

        await #expect(
            throws: MappingError.invalidConversion(type: "AppVersion", value: "1.2.3.4")
        ) {
            _ = try SettingMapper.appUpdatePolicy(from: response)
        }
    }

    @Test("updateDate 형식이 올바르지 않으면 invalidConversion 에러를 던진다")
    func throwsInvalidConversionWhenUpdateDateIsInvalid() async {
        let response = makeAppMinimumVersionResponse(updateDate: "2026-99-99")

        await #expect(
            throws: MappingError.invalidConversion(type: "UpdateDate", value: "2026-99-99")
        ) {
            _ = try SettingMapper.appUpdatePolicy(from: response)
        }
    }

    // MARK: - TermsAgreementDraft

    @Test("약관 응답을 TermsAgreementDraft로 변환한다")
    func mapsTermsAgreementDraft() {
        let response = makeTermSettingResponse(
            serviceAgreed: true,
            privacyAgreed: false,
            marketingAgreed: true
        )

        let result = SettingMapper.termsAgreementDraft(from: response)

        #expect(result.isAgreed(.serviceAgreement) == true)
        #expect(result.isAgreed(.privacyPolicy) == false)
        #expect(result.isAgreed(.marketingConsent) == true)
    }

    // MARK: - TermSettingRequest

    @Test("TermsAgreementDraft를 약관 요청 DTO로 변환한다")
    func mapsTermSettingRequest() {
        let draft = makeDraft(
            serviceAgreed: true,
            privacyAgreed: true,
            marketingAgreed: false
        )

        let result = SettingMapper.termSettingRequest(from: draft)

        #expect(result.serviceAgreed == true)
        #expect(result.privacyAgreed == true)
        #expect(result.marketingAgreed == false)
    }
}
