//
//  CheckForceUpdateRequirementUseCaseTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import Foundation
@testable import SettingDomain

@Suite("CheckForceUpdateRequirementUseCase")
struct CheckForceUpdateRequirementUseCaseTests {

    // MARK: - Tests
    @Test("현재 버전이 최소 버전보다 낮으면 강제 업데이트가 필요하다")
    func returnsTrueWhenCurrentIsLower() async throws {
        let repo = MockAppUpdateRepository()
        repo.result = .success(
            AppUpdatePolicy(minimumVersion: AppVersion(major: 2, minor: 0, patch: 0),
                            updateDate: nil)
        )

        let provider = MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 9, patch: 9))
        let sut = DefaultCheckForceUpdateRequirementUseCase(repository: repo, versionProvider: provider)

        let required = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(required == true)
    }

    @Test("현재 버전이 최소 버전과 같으면 강제 업데이트가 필요하지 않다")
    func returnsFalseWhenCurrentEqualsMinimum() async throws {
        let repo = MockAppUpdateRepository()
        repo.result = .success(
            AppUpdatePolicy(minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
                            updateDate: nil)
        )

        let provider = MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 0, patch: 0))
        let sut = DefaultCheckForceUpdateRequirementUseCase(repository: repo, versionProvider: provider)

        let required = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(required == false)
    }
    
    @Test("현재 버전이 최소 버전보다 높으면 강제 업데이트가 필요하지 않다")
    func returnsFalseWhenCurrentIsGreater() async throws {
        let repo = MockAppUpdateRepository()
        repo.result = .success(
            AppUpdatePolicy(minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
                            updateDate: nil)
        )

        let provider = MockAppVersionProvider(currentVersion: AppVersion(major: 1, minor: 0, patch: 1))
        let sut = DefaultCheckForceUpdateRequirementUseCase(repository: repo, versionProvider: provider)

        let required = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(required == false)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockAppUpdateRepository()
        repo.result = .failure(.networkUnavailable)

        let provider = MockAppVersionProvider(currentVersion: .zero)
        let sut = DefaultCheckForceUpdateRequirementUseCase(
            repository: repo,
            versionProvider: provider
        )

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.loadCallCount == 1)
    }
}
