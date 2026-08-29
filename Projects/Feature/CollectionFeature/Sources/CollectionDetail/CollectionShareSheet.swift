//
//  CollectionShareSheet.swift
//  CollectionFeature
//
//  Created by YunhakLee on 8/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import LinkPresentation
import SwiftUI
import UIKit

/// 컬렉션 공유 시트 — SwiftUI `ShareLink` 대신 `UIActivityViewController`를 직접 띄운다(#228).
///
/// `ShareLink`는 두 조합 모두 실측에서 깨졌다(iOS 26.5 시뮬레이터, 2026-08-29):
/// - `item: URL, message:` → "복사"가 URL과 메시지를 **별개 pasteboard 항목**으로 넣어, 카카오톡처럼
///   plain-text만 붙여넣는 입력창엔 메시지만 들어가고 `websoso://…`가 통째로 빠진다.
/// - `item: String` → 시트가 문자열을 **파일(텍스트 데이터)로 취급**해 "파일에 저장"은 뜨고 "복사"가 아예 없다.
///
/// `UIActivityViewController`에 `UIActivityItemSource`로 **문자열 하나**를 주면 "복사"·카카오톡·메시지 모두
/// 그 전체 텍스트(안내 + 딥링크 + 앱스토어 링크)를 받고, `LPLinkMetadata`로 시트 상단 미리보기(제목·표지)도
/// 유지된다. 두 번째 화면이 공유가 필요해지면 `WSSComponent`로 승격 검토(첫 사용처라 화면 폴더에 둔다).
struct CollectionShareSheet: UIViewControllerRepresentable {

    let text: String
    let previewTitle: String
    let previewImage: UIImage?
    /// 사용자가 액션을 고르거나 취소해 시트가 끝났을 때 — 감싼 `.sheet`의 `isPresented`를 내려야 다음에 또 뜬다.
    let onFinished: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let source = ShareItemSource(text: text, previewTitle: previewTitle, previewImage: previewImage)
        let controller = UIActivityViewController(activityItems: [source], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onFinished() }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// 공유 항목 = 문자열. 미리보기(`LPLinkMetadata`)만 따로 얹는다.
private final class ShareItemSource: NSObject, UIActivityItemSource {

    private let text: String
    private let previewTitle: String
    private let previewImage: UIImage?

    init(text: String, previewTitle: String, previewImage: UIImage?) {
        self.text = text
        self.previewTitle = previewTitle
        self.previewImage = previewImage
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        text
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        text
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = previewTitle
        if let previewImage {
            metadata.imageProvider = NSItemProvider(object: previewImage)
        }
        return metadata
    }
}
