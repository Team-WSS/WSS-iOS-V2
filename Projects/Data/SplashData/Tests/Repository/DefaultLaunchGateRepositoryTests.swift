//
//  DefaultLaunchGateRepositoryTests.swift
//  SplashDataTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import SplashData
import BaseDomain
import Networking
import SettingDomain
import SettingDomainTesting

/// 게이트 **판정 질문 3개의 답을 어디서 어떻게 구하는지** 명세 — 세션(키체인 토큰 존재),
/// 강제 업데이트(서버 최소 버전 vs 현재 버전), 약관(필수 약관 draft).
/// 이 구현은 **위임뿐이고 정책이 없다** — 실패를 통과시킬지 같은 결정은 전부
/// `BootstrapAppUseCaseTests`(SplashDomain)가 명세하므로, 여기서는 에러를 그대로 던지는 것까지가 계약이다.
@Suite
struct DefaultLaunchGateRepositoryTests {

    // MARK: - hasValidSession

    @Test("저장된 액세스 토큰이 있으면 세션이 있다고 판정한다")
    func storedTokenMeansValidSession() {
        let sut = makeSUT(tokenStore: StubSessionTokenStore(accessTokenValue: "token"))

        #expect(sut.hasValidSession() == true)
    }

    @Test("저장된 토큰이 없으면 세션이 없다고 판정한다")
    func missingTokenMeansNoSession() {
        let sut = makeSUT(tokenStore: StubSessionTokenStore(accessTokenValue: nil))

        #expect(sut.hasValidSession() == false)
    }

    @Test("토큰 읽기가 실패해도 크래시 없이 세션이 없다고 판정한다")
    func tokenReadFailureMeansNoSession() {
        let sut = makeSUT(tokenStore: StubSessionTokenStore(error: StubError.keychain))

        #expect(sut.hasValidSession() == false)
    }

    // MARK: - checkForceUpdateRequired

    @Test("현재 버전이 서버 최소 버전보다 낮으면 강제 업데이트가 필요하다고 판정한다")
    func lowerVersionRequiresForceUpdate() async throws {
        let appUpdate = MockAppUpdateRepository()
        appUpdate.result = .success(AppUpdatePolicy(
            minimumVersion: AppVersion(major: 2, minor: 0, patch: 0),
            updateDate: nil
        ))
        let sut = makeSUT(
            appUpdateRepository: appUpdate,
            versionProvider: MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 9, patch: 0))
        )

        #expect(try await sut.checkForceUpdateRequired() == true)
    }

    @Test("현재 버전이 서버 최소 버전 이상이면 강제 업데이트가 필요 없다고 판정한다")
    func equalOrHigherVersionDoesNotRequireForceUpdate() async throws {
        let appUpdate = MockAppUpdateRepository()
        appUpdate.result = .success(AppUpdatePolicy(
            minimumVersion: AppVersion(major: 2, minor: 0, patch: 0),
            updateDate: nil
        ))
        let sut = makeSUT(
            appUpdateRepository: appUpdate,
            versionProvider: MockAppVersionProvider(currentVersion: AppVersion(major: 2, minor: 0, patch: 0))
        )

        #expect(try await sut.checkForceUpdateRequired() == false)
    }

    @Test("최소 버전 조회 실패는 에러를 그대로 던진다 — 통과 여부 판단은 UseCase 몫이다")
    func policyLoadFailurePropagatesError() async {
        let appUpdate = MockAppUpdateRepository()
        appUpdate.result = .failure(.serverUnavailable)
        let sut = makeSUT(appUpdateRepository: appUpdate)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.checkForceUpdateRequired()
        }
    }

    // MARK: - isRequiredTermsAgreed

    @Test("필수 약관에 모두 동의한 draft면 동의로 판정한다")
    func allRequiredAgreedDraftIsAgreed() async throws {
        let terms = MockTermsAgreementRepository()
        terms.loadResult = .success(makeDraft(requiredAgreed: true))
        let sut = makeSUT(termsAgreementRepository: terms)

        #expect(try await sut.isRequiredTermsAgreed() == true)
    }

    @Test("필수 약관이 하나라도 미동의면 미동의로 판정한다")
    func missingRequiredAgreementIsNotAgreed() async throws {
        let terms = MockTermsAgreementRepository()
        terms.loadResult = .success(makeDraft(requiredAgreed: false))
        let sut = makeSUT(termsAgreementRepository: terms)

        #expect(try await sut.isRequiredTermsAgreed() == false)
    }

    // 여기서 에러를 삼키면 UseCase는 "동의함"과 구별할 수 없게 되고,
    // 세션 소실(.authenticationRequired)을 인트로로 보내는 정책도 함께 죽는다.
    @Test("약관 조회 실패는 에러를 그대로 던진다 — 통과 여부 판단은 UseCase 몫이다")
    func termsLoadFailurePropagatesError() async {
        let terms = MockTermsAgreementRepository()
        terms.loadResult = .failure(.authenticationRequired)
        let sut = makeSUT(termsAgreementRepository: terms)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.isRequiredTermsAgreed()
        }
    }
}

// MARK: - Helper

extension DefaultLaunchGateRepositoryTests {

    private func makeSUT(
        tokenStore: SessionTokenStore = StubSessionTokenStore(accessTokenValue: nil),
        appUpdateRepository: MockAppUpdateRepository = MockAppUpdateRepository(),
        versionProvider: MockAppVersionProvider = MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 0, patch: 0)),
        termsAgreementRepository: MockTermsAgreementRepository = MockTermsAgreementRepository()
    ) -> DefaultLaunchGateRepository {
        DefaultLaunchGateRepository(
            tokenStore: tokenStore,
            appUpdateRepository: appUpdateRepository,
            versionProvider: versionProvider,
            termsAgreementRepository: termsAgreementRepository
        )
    }

    /// 필수 약관(서비스·개인정보)만 requiredAgreed로 채운 draft. 선택 약관(마케팅)은 항상 미동의로 둔다.
    private func makeDraft(requiredAgreed: Bool) -> TermsAgreementDraft {
        var draft = TermsAgreementDraft()
        for type in TermsType.allCases where type.isRequired {
            draft.setAgreed(requiredAgreed, for: type)
        }
        return draft
    }
}

// MARK: - Test Doubles

private enum StubError: Error {
    case keychain
}

private struct StubSessionTokenStore: SessionTokenStore {
    var accessTokenValue: String?
    var error: Error?

    func accessToken() throws -> String? {
        if let error { throw error }
        return accessTokenValue
    }

    func clearTokens() throws {}
}
