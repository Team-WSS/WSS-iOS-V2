//
//  LoadAccountInfoDraftUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  LoadAccountInfoDraftUseCaseTests.swift
//  ProfileDomainTests
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadAccountInfoDraftUseCase")
struct LoadAccountInfoDraftUseCaseTests {

    private func makeAccountInfoDraft() -> AccountInfoDraft {
        // ✅ 프로젝트 타입에 맞게 여기만 조정하면 됨
        AccountInfoDraft(email: "H@Gmail.com", gender: .female, birth: try! BirthYear(1990))
    }

    @Test("계정 정보 초안을 조회할 수 있다")
    func loadsAccountInfoDraft() async throws {
        let repo = MockProfileRepository()
        let expected = makeAccountInfoDraft()
        repo.loadAccountInfoDraftResult = .success(expected)

        let sut = DefaultLoadAccountInfoDraftUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadAccountInfoDraftCallCount == 1)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.loadAccountInfoDraftResult = .failure(.notFound)

        let sut = DefaultLoadAccountInfoDraftUseCase(repository: repo)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await sut.execute()
        }

        #expect(repo.loadAccountInfoDraftCallCount == 1)
    }
}
