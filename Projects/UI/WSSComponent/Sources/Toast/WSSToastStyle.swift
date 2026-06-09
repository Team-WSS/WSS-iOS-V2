//
//  WSSToastStyle.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public extension WSSToastType {
    var image: Image {
        switch self {
        case .deleteBlockUser, .novelAlreadyConnected,
                .selectionOverLimit, .unknownUser, .networkDelay:
            return WSSImage.icAlertSuccess.swiftUIImage
        case .novelReviewed, .novelReviewDeleted, .feedEdited, .blockUser,
                .changePublic, .changePrivate, .changeInfo, .editProfile, .limitAddImage:
            return WSSImage.icAlertCheck.swiftUIImage
        case .unknownError:
            return WSSImage.icAlertWarning.swiftUIImage
        }
    }
    
    var text: String {
        switch self {
        case .blockUser(let nickname):          "\(nickname)님을 차단했어요"
        case .unknownUser:                      "웹소소를 떠난 유저예요"
        case .deleteBlockUser(let nickname):    "\(nickname)님을 차단 해제했어요"
        case .novelAlreadyConnected:            "하나의 작품만 연결할 수 있어요"
        case .selectionOverLimit(let count):    "\(count)개까지 선택 가능해요"
        case .limitAddImage(let limitCount):    "\(limitCount)장까지 업로드 가능해요"
        case .novelReviewed:                    "평가 완료!"
        case .novelReviewDeleted:               "평가를 모두 삭제했어요"
        case .feedEdited:                       "작성 완료!"
        case .changePublic:                     "프로필이 전체 공개로 전환되었어요"
        case .changePrivate:                    "프로필이 비공개로 전환되었어요"
        case .changeInfo:                       "성별/나이 정보가 수정되었어요"
        case .editProfile:                      "프로필 정보가 수정되었어요"
        case .networkDelay:                     "오류가 발생했어요. 다시 시도해주세요."
        case .unknownError:                     "알 수 없는 에러가 발생했어요"
        }
    }
}
