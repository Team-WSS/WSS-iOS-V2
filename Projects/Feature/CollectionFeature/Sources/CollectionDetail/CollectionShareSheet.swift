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

/// 컬렉션 공유 시트 프레젠터 — SwiftUI `ShareLink`/`.sheet` 대신 **투명 호스트 VC가 `UIActivityViewController`를
/// 직접 `present`** 한다(#228). 화면 `.background { }`에 깔아두고 `isPresented`를 올리면 뜬다.
///
/// 왜 이 구조인가(전부 iOS 26.5 시뮬레이터 실측, 2026-08-29):
/// - `ShareLink(item: URL, message:)` → "복사"가 URL과 메시지를 **별개 pasteboard 항목**으로 넣어, 카카오톡처럼
///   plain-text만 붙여넣는 입력창엔 메시지만 들어가고 `websoso://…`가 통째로 빠진다.
/// - `ShareLink(item: String)` → 시트가 문자열을 **파일(텍스트 데이터)로 취급**해 "파일에 저장"만 뜨고 "복사"가 없다.
/// - `.sheet { UIViewControllerRepresentable(UIActivityViewController) }` → 첫 번째는 뜨지만, 시트 안의 X/완료가
///   **UIKit 경로로 hosting 시트를 직접 내려** SwiftUI의 표시 상태와 어긋나고, 그 뒤로는 같은 창에서 공유 시트가
///   조용히 안 뜬다(새 화면 인스턴스에서도 재현 — 앱 재시작 전까지).
///
/// 호스트 VC가 직접 present/dismiss를 소유하면 SwiftUI 프레젠테이션 부기와 아예 얽히지 않는다. 종료는
/// `completionWithItemsHandler`(액션 완료·취소·스와이프 모두 호출)에서 `isPresented`를 내린다 — 안 내리면 다음
/// 탭에서 `true→true`라 `updateUIViewController`가 안 불려 안 뜬다.
/// 두 번째 화면이 공유가 필요해지면 `WSSComponent`로 승격 검토(첫 사용처라 화면 폴더에 둔다).
struct CollectionSharePresenter: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let text: String
    let previewTitle: String
    let previewImage: UIImage?

    /// 지금 떠 있는 컨테이너 — 중복 present 가드 + 완료 시 내리기용. `updateUIViewController`는 SwiftUI가
    /// 여러 번 부르므로 호스트 VC가 아니라 여기서 "이미 떠 있음"을 판단한다.
    final class Coordinator {
        weak var presented: UIViewController?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        return host
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        // 이미 떠 있거나(중복 present 방지) 아직 창에 안 붙었으면(present 불가) 건너뛴다.
        guard isPresented, context.coordinator.presented == nil, host.view.window != nil else { return }

        let source = ShareItemSource(text: text, previewTitle: previewTitle, previewImage: previewImage)
        let activity = UIActivityViewController(activityItems: [source], applicationActivities: nil)
        let isPresentedBinding = $isPresented
        let coordinator = context.coordinator
        activity.completionWithItemsHandler = { _, _, _, _ in
            isPresentedBinding.wrappedValue = false
            coordinator.presented = nil
        }
        // iPad는 popover로 뜨므로 anchor가 없으면 크래시한다.
        activity.popoverPresentationController?.sourceView = host.view

        // ⚠️ 호스트 VC(SwiftUI 안에 묻힌 투명 child)에서 present하지 말고 **창의 최상위 VC**(루트 hosting
        // controller, 그 위에 떠 있는 게 있으면 그것)에서 present한다 — 프레젠테이션 컨텍스트가 호스트가 되면
        // 시트 모양·뒤 화면 처리가 어긋난다(실측). 시트 모양 자체(딤·그래버·detent)는 iOS 26 공유 시트가
        // 스스로 정하며 우리 설정을 무시한다 — 컨테이너 VC에 child로 넣어 pageSheet로 강제하면 공유 시트가
        // 창 전체를 흰 백드롭으로 덮어 앱 화면이 사라져 보인다(실측, `clipsToBounds`로도 못 막음). 그래서
        // 모양은 시스템 기본에 맡긴다.
        coordinator.presented = activity
        topPresenter(from: host).present(activity, animated: true)
    }

    private func topPresenter(from host: UIViewController) -> UIViewController {
        var presenter = host
        while let parent = presenter.parent { presenter = parent }
        while let presented = presenter.presentedViewController { presenter = presented }
        return presenter
    }
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
