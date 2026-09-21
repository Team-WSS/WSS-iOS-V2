//
//  AuthMapper.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import AuthDomain

enum AuthMapper {
    
    // MARK: - DTO -> Entity
    
    static func needOnboarding(
        from response: LoginSuccessResponse
    ) -> NeedOnboarding {
        NeedOnboarding(value: !response.isRegister)
    }
    
    // MARK: - Entity -> DTO
    
    static func withdrawalReason(
        from draft: WithdrawalReasonDraft
    ) -> WithdrawRequest {
        let reason: String
        switch draft.option {
        case .notFrequentlyUsed: reason = "자주 사용하지 않아서"
        case .inconvenientAndBuggy: reason = "이용이 불편하고 장애가 많아서"
        case .wantToDeleteContent: reason = "삭제하고 싶은 내용이 있어서"
        case .noDesiredContent: reason = "원하는 작품이 없어서"
        case .custom: reason = draft.customReasonText
        }
        return WithdrawRequest(reason: reason)
    }
    
    static func appleSyncRequest(
        from credential: AppleSyncCredential
    ) -> AppleSyncRequest {
        AppleSyncRequest(
            authorizationCode: credential.authorizationCode,
            idToken: credential.idToken
        )
    }
}
