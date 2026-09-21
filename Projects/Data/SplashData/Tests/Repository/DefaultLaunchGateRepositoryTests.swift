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
import BaseData
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

    // MARK: - isOnboardingCompleted (#257)

    @Test("isRegistered가 true면 온보딩 완료로 판정한다")
    func registeredMeansOnboardingCompleted() {
        let appStorage = StubAppStorage()
        appStorage.set(.isRegistered, true)
        let sut = makeSUT(appStorage: appStorage)

        #expect(sut.isOnboardingCompleted() == true)
    }

    @Test("isRegistered가 false면 온보딩 미완료로 판정한다")
    func notRegisteredMeansOnboardingIncomplete() {
        let appStorage = StubAppStorage()
        appStorage.set(.isRegistered, false)
        let sut = makeSUT(appStorage: appStorage)

        #expect(sut.isOnboardingCompleted() == false)
    }

    // 기능 도입 전부터 로그인돼 있던 기존 유저는 이 키가 없다 — 온보딩으로 되돌리면 안 되므로 완료로 간주.
    @Test("isRegistered 값이 없으면(기존 로그인 유저) 온보딩 완료로 간주한다")
    func missingRegisteredDefaultsToCompleted() {
        let sut = makeSUT(appStorage: StubAppStorage())

        #expect(sut.isOnboardingCompleted() == true)
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
        appStorage: AppStorage = StubAppStorage(),
        appUpdateRepository: MockAppUpdateRepository = MockAppUpdateRepository(),
        versionProvider: MockAppVersionProvider = MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 0, patch: 0)),
        termsAgreementRepository: MockTermsAgreementRepository = MockTermsAgreementRepository()
    ) -> DefaultLaunchGateRepository {
        DefaultLaunchGateRepository(
            tokenStore: tokenStore,
            appStorage: appStorage,
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

/// 온보딩 완료 여부(#257) 판정만 검증하므로 `.isRegistered` 하나만 다루면 충분한 인메모리 저장소.
private final class StubAppStorage: AppStorage, @unchecked Sendable {
    private var values: [String: Any] = [:]

    func get<V>(_ key: StorageKey<V>) -> V? {
        values[key.rawValue] as? V
    }

    func set<V>(_ key: StorageKey<V>, _ value: V?) {
        if let value {
            values[key.rawValue] = value
        } else {
            values.removeValue(forKey: key.rawValue)
        }
    }

    func remove<V>(_ key: StorageKey<V>) {
        values.removeValue(forKey: key.rawValue)
    }
}
