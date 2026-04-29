import Testing
@testable import AuthData
import AuthDomain

@Suite("AuthMapper")
struct AuthMapperTests {

    // MARK: - Helpers

    private func makeLoginSuccessResponse(
        accessToken: String = "access",
        refreshToken: String = "refresh",
        isRegister: Bool = true
    ) -> LoginSuccessResponse {
        LoginSuccessResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            isRegister: isRegister
        )
    }

    private func makeWithdrawalReasonDraft(
        option: WithdrawalReasonOption = .notFrequentlyUsed,
        customText: String = ""
    ) -> WithdrawalReasonDraft {
        var draft = WithdrawalReasonDraft()
        draft.setOption(option)
        if option.requiresText {
            draft.setCustomReasonText(customText)
        }
        return draft
    }

    private func makeAppleSyncCredential(
        authorizationCode: String = "authCode",
        idToken: String = "idToken"
    ) -> AppleSyncCredential {
        AppleSyncCredential(authorizationCode: authorizationCode, idToken: idToken)
    }

    // MARK: - needOnboarding

    @Test("isRegister가 true이면 NeedOnboarding.value가 false")
    func mapsNeedOnboardingWhenRegistered() {
        let response = makeLoginSuccessResponse(isRegister: true)
        let result = AuthMapper.needOnboarding(from: response)
        #expect(result.value == false)
    }

    @Test("isRegister가 false이면 NeedOnboarding.value가 true")
    func mapsNeedOnboardingWhenNotRegistered() {
        let response = makeLoginSuccessResponse(isRegister: false)
        let result = AuthMapper.needOnboarding(from: response)
        #expect(result.value == true)
    }

    // MARK: - withdrawalReason

    @Test("모든 WithdrawalReasonOption을 올바른 텍스트로 매핑한다")
    func mapsAllWithdrawalReasonOptions() {
        let cases: [(option: WithdrawalReasonOption, customText: String, expectedReason: String)] = [
            (.notFrequentlyUsed, "", "자주 사용하지 않아서"),
            (.inconvenientAndBuggy, "", "이용이 불편하고 장애가 많아서"),
            (.wantToDeleteContent, "", "삭제하고 싶은 내용이 있어서"),
            (.noDesiredContent, "", "원하는 작품이 없어서"),
            (.custom, "직접 작성한 이유", "직접 작성한 이유"),
        ]

        for (option, customText, expectedReason) in cases {
            let draft = makeWithdrawalReasonDraft(option: option, customText: customText)
            let result = AuthMapper.withdrawalReason(from: draft)
            #expect(result.reason == expectedReason)
        }
    }

    // MARK: - appleSyncRequest

    @Test("AppleSyncCredential을 AppleSyncRequest로 올바르게 매핑한다")
    func mapsAppleSyncRequest() {
        let credential = makeAppleSyncCredential(
            authorizationCode: "testAuthCode",
            idToken: "testIdToken"
        )
        let result = AuthMapper.appleSyncRequest(from: credential)
        #expect(result.authorizationCode == "testAuthCode")
        #expect(result.idToken == "testIdToken")
    }
}
