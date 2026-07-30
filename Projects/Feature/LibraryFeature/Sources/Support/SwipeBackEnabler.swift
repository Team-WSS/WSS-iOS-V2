//
//  SwipeBackEnabler.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

/// 화면 왼쪽 가장자리 스와이프 뒤로가기를 되살린다.
/// iOS는 시스템 네비바를 숨기면(`.toolbar(.hidden)`) `interactivePopGestureRecognizer`도 함께 끈다 —
/// 디자인 폰트·아이콘을 맞추려고 커스텀 헤더를 쓰는 화면에선 그 부작용으로 스와이프 pop이 죽는다.
/// 그래서 조상 `UINavigationController`를 찾아 제스처를 다시 켜고, **delegate를 직접 맡아**
/// ⚠️ 루트 화면에선 시작하지 않게 막는다 — 되돌아갈 화면이 없는데 발화하면 내비게이션이 얼어붙는다.
/// (delegate를 그냥 `nil`로 두면 이 가드가 사라져 루트에서 그 사고가 난다.)
/// ⚠️ `UIGestureRecognizer.delegate`는 약한 참조라 Coordinator가 살아 있어야 한다(Representable이 붙어 있는 동안 유지).
///
/// ⚠️ **`NovelDetailFeature`에 같은 구현이 있다**(몰입형 헤더용) — 커스텀 헤더를 쓰는 화면이 늘면
/// 공용 모듈로 승격을 검토할 것. 지금은 두 Feature가 서로를 import하지 않는 규칙 때문에 복제 상태다.
struct SwipeBackEnabler: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    // 삽입 시점엔 responder chain이 안 이어져 makeUIView에선 못 찾는다 → 레이아웃 후(updateUIView + async)에 건다.
    // 매 갱신마다 다시 거는 건 의도적 — 다른 화면을 다녀오며 네비바 숨김이 재적용돼 제스처가 도로 꺼져도 되살아난다.
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { [weak uiView] in
            guard let navigationController = uiView?.enclosingNavigationController else { return }
            context.coordinator.enableSwipeBack(on: navigationController)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var navigationController: UINavigationController?

        func enableSwipeBack(on navigationController: UINavigationController) {
            self.navigationController = navigationController
            guard let gesture = navigationController.interactivePopGestureRecognizer else { return }
            gesture.isEnabled = true
            gesture.delegate = self
        }

        /// 스택에 되돌아갈 화면이 있을 때만 제스처를 시작시킨다(루트에선 무시).
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

private extension UIView {
    /// responder chain(= 뷰 계층이 아니라 뷰컨트롤러까지 이어지는 사슬)을 거슬러 올라
    /// 이 뷰를 품은 `UINavigationController`를 찾는다. SwiftUI 뷰는 hosting 뷰컨트롤러의
    /// child라 superview 체인만으론 뷰컨트롤러에 닿지 못한다.
    var enclosingNavigationController: UINavigationController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let navigationController = current as? UINavigationController { return navigationController }
            if let navigationController = (current as? UIViewController)?.navigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}
