//
//  WSSNavigationBar.swift
//  WSSComponent
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 커스텀 네비게이션 바 — 뒤로가기 + 가운데 타이틀 (+ 선택적 우측 액션).
///
/// 시스템 네비바 대신 쓰는 이유는 **폰트와 back 아이콘이 디자인과 다르고**(iOS 26에선 리퀴드 글래스로도 뜬다),
/// 그 대가로 호출부는 화면 전체에 **`.wssCustomNavigationBar()`** 한 줄을 함께 걸어야 한다
/// (시스템 네비바를 숨기고, 그 부작용으로 함께 꺼지는 스와이프 뒤로가기를 되살린다 — 아래 modifier 참고).
///
/// - Parameters:
///   - title: 가운데 타이틀. 대상의 이름이 아니라 **화면 이름**을 넣는다(예: "알림", "서재").
///   - onBack: 뒤로가기(또는 닫기) 탭 콜백. 보통 호출부의 `@Environment(\.dismiss)`를 넘긴다 —
///     어디로 가는지는 화면이 정한다(컴포넌트는 내비게이션 정책을 모른다). 저장 전 확인이 필요한
///     화면은 `dismiss` 대신 `{ viewModel.handle(.requestClose) }`처럼 자기 액션을 넘긴다.
///   - trailing: 우측 액션 슬롯(예: "완료" 버튼, 설정 아이콘). 기본은 비어 있다(back+title만).
// ⚠️ 제네릭 타입(`WSSNavigationBar<Trailing>`) 안에는 static stored property를 둘 수 없어
// (Swift 제약) Metric을 파일 스코프로 뺀다.
private enum WSSNavigationBarMetric {
    /// 시스템 네비바(inline)와 같은 높이.
    static let barHeight: CGFloat = 44
    /// 애플 권장 탭 타깃(44)에 맞춘 히트 영역.
    static let backButtonSize: CGFloat = 44
    static let backIconSize: CGFloat = 24
    /// 디자인의 뒤로가기는 화면 왼쪽 끝이 아니라 6pt 안쪽에서 시작한다.
    static let backButtonLeading: CGFloat = 6
    /// 우측 액션은 WSS 표준 side margin(20)에 맞춰 오른쪽 끝에서 20pt 안쪽에 둔다.
    static let trailingInset: CGFloat = 20
}

public struct WSSNavigationBar<Trailing: View>: View {

    private typealias Metric = WSSNavigationBarMetric

    private let title: String
    private let onBack: () -> Void
    private let trailing: Trailing

    public init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        // 타이틀을 ZStack 중앙에 두는 건 의도다 — HStack에 넣으면 뒤로가기 버튼 폭만큼 오른쪽으로 밀린다.
        ZStack {
            Text(title)
                .applyWSSFont(.title2, color: .wssBlack)

            HStack(spacing: 0) {
                Button(action: onBack) {
                    WSSImage.icNavigateLeft.swiftUIImage
                        // ⚠️ 이 에셋의 원색은 연회색(#C7C7D0)이라 그대로 쓰면 디자인의 검정 화살표보다 훨씬 흐리다
                        // (DesignSystem의 "아이콘 SVG는 원색 고정") → template으로 색을 입힌다.
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssBlack)
                        .frame(width: Metric.backIconSize, height: Metric.backIconSize)
                        // 아이콘 24를 44 히트 영역 가운데 둔다.
                        .frame(width: Metric.backButtonSize, height: Metric.backButtonSize)
                        .contentShape(Rectangle())
                }

                Spacer()

                // 우측 액션 슬롯. EmptyView면 자리도 차지하지 않는다(back+title만인 화면).
                trailing
                    .padding(.trailing, Metric.trailingInset)
            }
            // ⚠️ `.padding(.horizontal,)`을 쓰지 말 것 — 양쪽에 걸려 반대편 요소까지 민다.
            .padding(.leading, Metric.backButtonLeading)
        }
        .frame(height: Metric.barHeight)
    }
}

// 우측 액션이 없는 화면(back+title만)을 위한 편의 init — 기존 호출부 `WSSNavigationBar(title:onBack:)`가
// 그대로 컴파일된다(트레일링 클로저는 `onBack`으로 붙는다).
public extension WSSNavigationBar where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

// MARK: - 화면 modifier

public extension View {

    /// 시스템 네비바(iOS 26 리퀴드 글래스)를 숨겨 **플랫한 커스텀 헤더**(`WSSNavigationBar`)를 쓰게 하고,
    /// 네비바 숨김이 함께 꺼버리는 **스와이프 뒤로가기까지 되살린다** — 이 한 줄이 예전의
    /// `.toolbar(.hidden, for: .navigationBar)` + `.enableSwipeBack()` 두 줄을 대신한다.
    /// 그래서 커스텀 헤더 화면은 `SwipeBackEnabler`(`.enableSwipeBack()`)를 따로 선언할 필요가 없다.
    ///
    /// - Parameter swipeBackEnabled: 기본 `true`. **닫기 전 확인이 필요한 화면**(작성 중 초안 등,
    ///   예: `NovelReviewView`의 "그만하기" 알럿, `CreateCollectionView`)은 `false`로 준다 —
    ///   `navigationItem.hidesBackButton`을 세워 **전역 pop 제스처 delegate가 이 화면에서 스와이프 pop 시작을
    ///   거부**하게 한다(delegate가 스택 공유라, 부모 화면이 이미 `.enableSwipeBack()`을 걸었어도 이 플래그로 막힌다).
    ///   그 대신 화면은 커스텀 back 버튼 → 확인 알럿 → 닫기로만 나가게 한다.
    func wssCustomNavigationBar(swipeBackEnabled: Bool = true) -> some View {
        modifier(WSSCustomNavigationBarModifier(swipeBackEnabled: swipeBackEnabled))
    }
}

private struct WSSCustomNavigationBarModifier: ViewModifier {

    let swipeBackEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if swipeBackEnabled {
            // 시스템 네비바만 숨기고, 네비바 숨김이 함께 꺼버리는 스와이프백을 제스처로 되살린다
            // (Notification·NovelDetail 등 검증된 패턴과 동일).
            // ⚠️ `.navigationBarBackButtonHidden(false)`를 명시로 걸지 말 것 — iOS 26에서 그게 시스템
            // back 버튼(리퀴드 글래스)을 강제로 띄워, 투명 커스텀 바(컬렉션 상세 등) 위로 비쳐 보인다.
            // 걸지 않으면 기본값(hidesBackButton=false)이라 스와이프 delegate 가드도 통과한다.
            content
                .toolbar(.hidden, for: .navigationBar)
                .enableSwipeBack()
        } else {
            // 닫기 전 확인이 필요한 화면(작성 중 초안 등): hidesBackButton=true로 전역 pop 제스처
            // delegate가 이 화면의 스와이프 pop 시작을 거부하게 한다(스와이프백 미적용).
            content
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        WSSNavigationBar(title: "알림") { print("뒤로가기") }
        WSSNavigationBar(title: "프로필 공개 설정") {
            print("뒤로가기")
        } trailing: {
            Text("완료")
                .applyWSSFont(.title2, color: .wssPrimary100)
        }
        Spacer()
    }
}
