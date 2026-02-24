//
//  SaveAccountInfoDraftUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  SaveAccountInfoDraftUseCaseTests.swift
//  ProfileDomainTests
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("SaveAccountInfoDraftUseCase")
struct SaveAccountInfoDraftUseCaseTests {

    private func makeAccountInfoDraft() -> AccountInfoDraft {
        // ✅ 프로젝트 타입에 맞게 여기만 조정하면 됨
        AccountInfoDraft(email: "H@Gmail.com", gender: .female, birth: try! BirthYear(1990))
    }

    @Test("계정 정보 초안을 저장할 수 있다")
    func savesAccountInfoDraft() async throws {
        let repo = MockProfileRepository()
        repo.saveAccountInfoResult = .success(())

        let sut = DefaultSaveAccountInfoDraftUseCase(repository: repo)
        let info = makeAccountInfoDraft()

        try await sut.execute(info)

        #expect(repo.saveAccountInfoCallCount == 1)
        #expect(repo.savedAccountInfos == [info])
    }

    @Test("저장 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.saveAccountInfoResult = .failure(.serverUnavailable)

        let sut = DefaultSaveAccountInfoDraftUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(makeAccountInfoDraft())
        }

        #expect(repo.saveAccountInfoCallCount == 1)
    }
}
