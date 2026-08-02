//
//  SwipeBackEnabler.swift
//  WSSComponent
//
//  Created by YunhakLee on 8/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - View Modifier

public extension View {

    /// 화면 왼쪽 가장자리 스와이프 뒤로가기를 되살린다.
    ///
    /// iOS는 시스템 네비바를 숨기면(`.toolbar(.hidden, for: .navigationBar)`) `interactivePopGestureRecognizer`도
    /// 함께 끈다 — 디자인 폰트·아이콘을 맞추려고 **커스텀 헤더**를 쓰는 화면에선 그 부작용으로 스와이프 pop이 죽는다.
    /// 커스텀 헤더 화면의 `body` 끝에 이 modifier를 건다(내부에서 `.background`로 조립하므로 호출부는 신경 쓰지 않아도 된다).
    ///
    /// ⚠️ **`.navigationBarBackButtonHidden(true)`를 쓴 화면에는 의도적으로 동작하지 않는다.**
    /// 그건 "닫기 전에 확인받아야 하는 화면"이라는 신호로 쓰이고 있어(`NovelReviewView`의 "그만하기" 알럿),
    /// 스와이프로 그 확인을 건너뛰지 못하게 막는다. 커스텀 헤더가 필요하면 `.toolbar(.hidden, for: .navigationBar)`를 쓸 것
    /// — 이쪽은 그 플래그를 세우지 않아(실측) 스와이프백이 정상 동작한다.
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler())
    }
}

// MARK: - Enabler

/// 조상 `UINavigationController`를 찾아 pop 제스처를 다시 켜고, **delegate를 그 네비게이션 컨트롤러 자신에게** 맡긴다.
///
/// ⚠️ **delegate를 별도 Coordinator에 맡기지 말 것** — `UIGestureRecognizer.delegate`는 **약한 참조**라
/// 그 객체가 해제되면 nil이 되는데, UIKit은 nav controller를 만들 때 한 번만 delegate를 꽂으므로 **스스로 돌아오지 않는다**.
/// 그러면 `shouldBegin` 기본값(YES)이 적용돼 **되돌아갈 화면이 없는 루트에서도 pop 전환이 시작되고 내비게이션이 얼어붙는다.**
/// "떠날 때 반납" 방식으로 막으려 하면 반납 시점·늦게 도착한 재부착과의 경합을 매번 정확히 맞춰야 한다.
/// **네비게이션 컨트롤러 자신은 스택이 사는 내내 살아 있어** 이 수명 문제가 통째로 사라진다 — 반납도, 경합 가드도 필요 없다.
/// (구 WSSiOS도 같은 이유로 반납 없이 각 뷰컨트롤러가 `delegate = self`를 꽂았다.)
private struct SwipeBackEnabler: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    // 삽입 시점엔 responder chain이 안 이어져 makeUIView에선 못 찾는다 → 레이아웃 후(updateUIView + async)에 건다.
    // 매 갱신마다 다시 거는 건 의도적 — 다른 화면을 다녀오며 네비바 숨김이 재적용돼 제스처가 도로 꺼져도 되살아난다.
    // 늘 같은 값(네비게이션 컨트롤러 자신)을 꽂으므로 몇 번을 다시 걸든, 화면이 사라진 뒤 늦게 실행되든 무해하다.
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { [weak uiView] in
            guard let navigationController = uiView?.enclosingNavigationController,
                  let gesture = navigationController.interactivePopGestureRecognizer else { return }
            gesture.isEnabled = true
            gesture.delegate = navigationController
        }
    }
}

// MARK: - Gesture Delegate

/// ⚠️ **앱 전역에 단 한 번만 선언한다**(같은 타입에 두 모듈이 각각 준수를 붙이면 런타임 동작이 정의되지 않는다).
/// 그래서 Feature마다 복제하지 않고 WSSComponent가 유일한 정의처다.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {

    /// pop 제스처를 **시작해도 되는지**만 판정한다.
    ///
    /// ⚠️ 이 준수는 앱 전역이라 pop 제스처가 아닌 recognizer가 물어올 수도 있다 —
    /// 그때는 UIKit 기본값(`true`)을 그대로 돌려줘야 한다. `false`로 답하면 남의 제스처를 막는다.
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        // 되돌아갈 화면이 없는 루트에서 발화하면 pop 대상 없는 전환이 시작돼 내비게이션이 얼어붙는다.
        guard viewControllers.count > 1 else { return false }
        // ⚠️ 뒤로가기 버튼을 숨긴 화면은 "함부로 나가면 안 되는 화면"이다 — UIKit 기본 delegate가 보던 조건.
        // `.navigationBarBackButtonHidden(true)` + 커스텀 back으로 **닫기 전 확인 알럿**을 강제하는 화면
        // (`NovelReviewView`)이 이 성질에 기대고 있어서, 빼면 스와이프로 알럿 없이 빠져나가 작성 중이던 초안이 사라진다.
        // 커스텀 헤더 화면(`.toolbar(.hidden, for: .navigationBar)`)은 이 플래그가 서지 않으므로(실측: false)
        // 이 가드가 `.enableSwipeBack()`의 본래 목적을 막지는 않는다.
        guard topViewController?.navigationItem.hidesBackButton != true else { return false }
        // ⚠️ 전환이 도는 중이면 시작시키지 않는다(UIKit 기본 delegate가 하던 일 — 우리가 delegate를 맡았으니 함께 가져온다).
        // 셀을 탭해 push 애니메이션이 도는 중에 엣지를 밀면 그 위에 인터랙티브 pop이 겹쳐 스택이 깨진다.
        // `transitionCoordinator`는 전환 중에만 non-nil이고 이 메서드는 제스처 **시작 시점**에만 불리므로,
        // 자기 자신이 만들어낼 인터랙티브 pop을 막지는 않는다.
        return transitionCoordinator == nil
    }
}

// MARK: - Helper

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
