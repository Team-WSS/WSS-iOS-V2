//
//  LoadProfileCharacterUseCaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadProfileCharacterUseCase")
struct LoadProfileCharacterUseCaseTests {

    @Test("프로필 캐릭터 목록을 반환한다")
    func returnsProfileCharacters() async throws {
        let repo = MockProfileRepository()
        let expected = [makeCharacter(id: 1, isRepresentative: true), makeCharacter(id: 2)]
        repo.fetchProfileCharactersResult = .success(expected)

        let sut = DefaultLoadProfileCharacterUseCase(profileRepository: repo)

        let result = try await sut.execute()

        #expect(repo.fetchProfileCharactersCallCount == 1)
        #expect(result.count == 2)
        #expect(result.first?.id == 1)
    }

    @Test("캐릭터가 없으면 빈 배열을 반환한다")
    func returnsEmptyWhenNoCharacters() async throws {
        let repo = MockProfileRepository()
        repo.fetchProfileCharactersResult = .success([])

        let sut = DefaultLoadProfileCharacterUseCase(profileRepository: repo)

        let result = try await sut.execute()

        #expect(result.isEmpty)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.fetchProfileCharactersResult = .failure(.serverUnavailable)

        let sut = DefaultLoadProfileCharacterUseCase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.fetchProfileCharactersCallCount == 1)
    }
}

extension LoadProfileCharacterUseCaseTests {

    private func makeCharacter(
        id: Int = 1,
        isRepresentative: Bool = false
    ) -> ProfileCharacter {
        ProfileCharacter(
            id: id,
            name: "캐릭터\(id)",
            line: "한마디",
            representativeImage: nil,
            thumbnailImage: nil,
            isRepresentative: isRepresentative
        )
    }
}
