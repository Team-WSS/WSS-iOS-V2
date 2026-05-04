//
//  WSSAlertStyle.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WSSAlertContent {
    let iconImage: Image?
    let title: String
    let titleFont: WSSFontStyle
    let titleBottomPadding: CGFloat
    let subtitle: String?
    let subtitleFont: WSSFontStyle?
    let subtitleColor: Color?
    let subTitlePadding: CGFloat?
    let leftButton: WSSAlertButtonContent?
    let rightButton: WSSAlertButtonContent
}

public struct WSSAlertButtonContent {
    let title: String
    let backgroundColor: Color

    var textColor: Color {
        switch backgroundColor {
        case WSSColor.wssPrimary100.swiftUIColor,
             WSSColor.wssSecondary100.swiftUIColor:
            WSSColor.wssWhite.swiftUIColor
        default:
            WSSColor.wssGray300.swiftUIColor
        }
    }
}

public extension WSSAlertType {
    var content: WSSAlertContent {
        switch self {
        case .needTermsAgreement:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "약관 동의가 필요해요!",
                titleFont: .title1,
                titleBottomPadding: 4,
                subtitle: "더 안전하고 원활한 웹소소를 위해\n업데이트된 약관에 동의해주세요.",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray200.swiftUIColor,
                subTitlePadding: 18,
                leftButton: nil,
                rightButton: WSSAlertButtonContent(
                    title: "동의하러 가기",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .needVersionUpdate:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "업데이트 알림",
                titleFont: .title1,
                titleBottomPadding: 4,
                subtitle: "웹소소 세계에 변화가 생겼어요!\n지금 업데이트 해보세요.",
                subtitleFont: .label1,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 18,
                leftButton: nil,
                rightButton: WSSAlertButtonContent(
                    title: "업데이트",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .stopNovelReview:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "평가를 그만할까요?",
                titleFont: .title2,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "그만하기",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "계속 작성",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .deleteNovelReviewDate:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "날짜 정보를 삭제할까요?",
                titleFont: .title2,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "삭제",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .deleteNovelReview:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "평가를 모두 삭제할까요?",
                titleFont: .title1,
                titleBottomPadding: 10,
                subtitle: "별점, 상태, 날짜, 매력포인트, 키워드\n정보가 사라지고 되돌릴 수 없어요",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 24,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "삭제",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .deleteMyFeed:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "해당 글을 삭제할까요?",
                titleFont: .title1,
                titleBottomPadding: 10,
                subtitle: "삭제한 글은 되돌릴 수 없어요",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 24,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "삭제",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .deleteMyComment:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "내 댓글을 삭제할까요?",
                titleFont: .title1,
                titleBottomPadding: 10,
                subtitle: "삭제한 댓글은 되돌릴 수 없어요",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 24,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "삭제",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .alreadyDeletedFeed:
            WSSAlertContent(
                iconImage: nil,
                title: "해당 글을 찾을 수 없어요",
                titleFont: .title2,
                titleBottomPadding: 24,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: nil,
                rightButton: WSSAlertButtonContent(
                    title: "확인",
                    backgroundColor: WSSColor.wssGray70.swiftUIColor
                )
            )

        case .reportImproperContent:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "해당 글에 부적절한 표현이\n사용되었나요?",
                titleFont: .title2,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "신고",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .receivedReportImproperContent:
            WSSAlertContent(
                iconImage: WSSImage.icReportCheck.swiftUIImage,
                title: "신고가 접수되었어요!",
                titleFont: .title1,
                titleBottomPadding: 10,
                subtitle: "해당 글이 커뮤니티 가이드를\n위반했는지 검토할게요",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 24,
                leftButton: nil,
                rightButton: WSSAlertButtonContent(
                    title: "확인",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .reportSpoilerContent:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "해당 글이 스포일러를 포함하고 있나요?",
                titleFont: .title2,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "신고",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .receivedReportSpoilerContent:
            WSSAlertContent(
                iconImage: WSSImage.icReportCheck.swiftUIImage,
                title: "신고가 접수되었어요!",
                titleFont: .title1,
                titleBottomPadding: 24,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: nil,
                rightButton: WSSAlertButtonContent(
                    title: "확인",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .stopWritingFeed:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "글 작성을 그만하시겠어요?",
                titleFont: .title2,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "그만하기",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "계속 작성",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .blockUser:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "해당 유저를 차단할까요?",
                titleFont: .title1,
                titleBottomPadding: 4,
                subtitle: "상대의 게시글, 댓글,\n프로필을 볼 수 없어요",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 18,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "차단",
                    backgroundColor: WSSColor.wssSecondary100.swiftUIColor
                )
            )

        case .setAppNotification:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "앱 알림이 꺼져있어요",
                titleFont: .title1,
                titleBottomPadding: 10,
                subtitle: "중요한 소식만 전해드릴게요!\n기기 설정에서 알림을 허용해주세요.",
                subtitleFont: .body2,
                subtitleColor: WSSColor.wssGray300.swiftUIColor,
                subTitlePadding: 24,
                leftButton: WSSAlertButtonContent(
                    title: "다음에 하기",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "설정하러 가기",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )

        case .logout:
            WSSAlertContent(
                iconImage: WSSImage.icModalWarning.swiftUIImage,
                title: "로그아웃 할까요?",
                titleFont: .title1,
                titleBottomPadding: 18,
                subtitle: nil,
                subtitleFont: nil,
                subtitleColor: nil,
                subTitlePadding: nil,
                leftButton: WSSAlertButtonContent(
                    title: "취소",
                    backgroundColor: WSSColor.wssGray50.swiftUIColor
                ),
                rightButton: WSSAlertButtonContent(
                    title: "로그아웃",
                    backgroundColor: WSSColor.wssPrimary100.swiftUIColor
                )
            )
        }
    }
}
