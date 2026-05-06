//
//  DefaultProfileRepositoryTests.swift
//  ProfileDataTests
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import ProfileData
@testable import ProfileDataTesting
import ProfileDomain
import BaseDomain
import BaseData
import Networking

@Suite
struct DefaultProfileRepositoryTests {

    // MARK: - syncUserBasicInfo

    @Test("syncUserBasicInfo 성공 시 localStorage에 저장")
    func syncUserBasicInfo_success_savesToLocalStorage() async throws {
        let (sut, service, localStorage) = makeRepository()
        service.getUserBasicInfoResult = .success(
            UserInfoResponse(userId: 42, gender: "MALE", nickname: "홍길동")
        )

        try await sut.syncUserBasicInfo()

        #expect(localStorage.userID == 42)
        #expect(localStorage.nickname == "홍길동")
        #expect(localStorage.gender == "MALE")
    }

    @Test("syncUserBasicInfo 네트워크 오류 시 RepositoryError 변환")
    func syncUserBasicInfo_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.getUserBasicInfoResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.syncUserBasicInfo()
        }
    }

    // MARK: - validateNickname

    @Test("validateNickname 사용 가능한 닉네임")
    func validateNickname_available() async throws {
        let (sut, service, _) = makeRepository()
        service.validateNicknameResult = .success(NicknameValidationResponse(isValid: true))

        let result = try await sut.validateNickname("새닉네임")

        #expect(result == true)
        #expect(service.validatedNicknames == ["새닉네임"])
    }

    @Test("validateNickname 중복된 닉네임")
    func validateNickname_duplicated() async throws {
        let (sut, service, _) = makeRepository()
        service.validateNicknameResult = .success(NicknameValidationResponse(isValid: false))

        let result = try await sut.validateNickname("기존닉네임")

        #expect(result == false)
    }

    @Test("validateNickname 네트워크 오류 시 RepositoryError 변환")
    func validateNickname_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.validateNicknameResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.validateNickname("닉네임")
        }
    }

    // MARK: - fetchUserProfile

    @Test("fetchUserProfile .me 타겟 시 localStorage UserID 사용")
    func fetchUserProfile_me_usesLocalStorageUserID() async throws {
        let (sut, service, localStorage) = makeRepository()
        localStorage.userID = 99
        service.getUserProfileResult = .success(
            UserProfileResponse(
                nickname: "testUser", intro: "소개",
                avatarImage: "", isProfilePublic: true, genrePreferences: ["romance"]
            )
        )

        _ = try await sut.fetchUserProfile(target: .me)

        #expect(service.getUserProfileUserIDs == [99])
    }

    @Test("fetchUserProfile .me 타겟 시 userID 없으면 notFound 에러")
    func fetchUserProfile_me_noUserID_throwsNotFound() async {
        let (sut, _, _) = makeRepository()

        await #expect(throws: RepositoryError.notFound) {
            try await sut.fetchUserProfile(target: .me)
        }
    }

    @Test("fetchUserProfile .user 타겟 시 주어진 UserID 사용")
    func fetchUserProfile_user_usesGivenUserID() async throws {
        let (sut, service, _) = makeRepository()
        service.getUserProfileResult = .success(
            UserProfileResponse(
                nickname: "otherUser", intro: "",
                avatarImage: "", isProfilePublic: false, genrePreferences: []
            )
        )

        _ = try await sut.fetchUserProfile(target: .user(UserID(55)))

        #expect(service.getUserProfileUserIDs == [55])
    }

    // MARK: - loadInitialProfile

    @Test("loadInitialProfile 성공 시 localStorage와 API 데이터 결합")
    func loadInitialProfile_success_combinesLocalStorageAndAPI() async throws {
        let (sut, service, localStorage) = makeRepository()
        localStorage.characterID = 7
        service.getProfileEditInfoResult = .success(
            UserProfileResponse(
                nickname: "저장된닉네임",
                intro: "소개글",
                avatarImage: "",
                isProfilePublic: nil,
                genrePreferences: ["ROMANCE"]
            )
        )

        let draft = try await sut.loadInitialProfile()

        #expect(draft.nickname.text == "저장된닉네임")
        #expect(draft.characterID == 7)
        #expect(draft.introduction == "소개글")
        #expect(draft.genrePreferences.count == 1)
    }

    @Test("loadInitialProfile 네트워크 오류 시 RepositoryError 변환")
    func loadInitialProfile_networkError_throwsRepositoryError() async {
        let (sut, service, _) = makeRepository()
        service.getProfileEditInfoResult = .failure(NetworkingError.unknown(MockError.stub))

        await #expect(throws: RepositoryError.self) {
            try await sut.loadInitialProfile()
        }
    }

    // MARK: - updateProfile

    @Test("updateProfile localStorage에 닉네임과 캐릭터ID 저장")
    func updateProfile_savesNicknameAndCharacterIDToLocalStorage() async throws {
        let (sut, _, localStorage) = makeRepository()
        let draft = makeDraft(nickname: "새닉네임", characterID: 5)

        try await sut.updateProfile(draft)

        #expect(localStorage.nickname == "새닉네임")
        #expect(localStorage.characterID == 5)
    }

    @Test("updateProfile 소개글/장르 변경 없으면 API 미호출")
    func updateProfile_noContentChange_doesNotCallAPI() async throws {
        let (sut, service, _) = makeRepository()
        let draft = makeDraft(nickname: "닉네임", characterID: 1)

        try await sut.updateProfile(draft)

        #expect(service.putProfileCallCount == 0)
    }

    // MARK: - profileVisibility

    @Test("loadProfileVisibility 성공")
    func loadProfileVisibility_success() async throws {
        let (sut, service, _) = makeRepository()
        service.getProfileVisibilityResult = .success(ProfileVisibilityResponse(isProfilePublic: false))

        let visibility = try await sut.loadProfileVisibility()

        #expect(visibility.isPublic == false)
    }

    @Test("updateProfileVisibility 성공")
    func updateProfileVisibility_success() async throws {
        let (sut, service, _) = makeRepository()

        try await sut.updateProfileVisibility(ProfileVisibility(isPublic: true))

        #expect(service.putProfileVisibilityCallCount == 1)
    }

    // MARK: - 네트워크 에러 → RepositoryError 변환

    @Test("NetworkingError.responseFailure 401은 authenticationRequired로 변환")
    func networkError_401_convertsToAuthenticationRequired() async {
        let (sut, service, localStorage) = makeRepository()
        localStorage.userID = 1
        service.getUserProfileResult = .failure(NetworkingError.responseFailure(code: 401, body: nil))

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.fetchUserProfile(target: .me)
        }
    }

    @Test("NetworkingError.responseFailure 404는 notFound로 변환")
    func networkError_404_convertsToNotFound() async {
        let (sut, service, localStorage) = makeRepository()
        localStorage.userID = 1
        service.getUserProfileResult = .failure(NetworkingError.responseFailure(code: 404, body: nil))

        await #expect(throws: RepositoryError.notFound) {
            try await sut.fetchUserProfile(target: .me)
        }
    }
}

// MARK: - Helpers

private extension DefaultProfileRepositoryTests {

    func makeRepository() -> (
        DefaultProfileRepository,
        MockProfileService,
        MockProfileLocalStorage
    ) {
        let service = MockProfileService()
        let localStorage = MockProfileLocalStorage()
        let sut = DefaultProfileRepository(
            service: service,
            localStorage: localStorage,
            logger: DataLogger(moduleName: "ProfileData")
        )
        return (sut, service, localStorage)
    }

    func makeDraft(nickname: String, characterID: Int) -> ProfileDraft {
        ProfileDraft(
            characterID: characterID,
            nickname: nickname,
            introduction: "소개",
            genrePreferences: []
        )
    }
}
