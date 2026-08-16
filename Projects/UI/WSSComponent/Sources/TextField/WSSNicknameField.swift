//
//  WSSNicknameField.swift
//  WSSComponent
//
//  Created by Guryss on 8/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 닉네임 입력 필드(텍스트+지우기/성공/실패 아이콘) + 중복확인 버튼 + 캡션(+선택적 글자수 카운터).
/// `OnboardingFeature`의 닉네임 화면과 `UserPageFeature`의 프로필 편집 화면이 같은 `ProfileDomain.NicknameDraft`를
/// 쓰면서 필드 UI만 각자 손으로 맞추다 드리프트가 생겨(여백·폰트·아이콘 로직 미세 불일치) 공용 컴포넌트로 승격했다.
///
/// **도메인을 모른다** — `NicknameDraft.ValidationState`는 `ProfileDomain` 타입이라 이 컴포넌트(UI 레이어)가
/// 알 수 없다(레이어 규칙). 그래서 검증 상태를 여기서 판단하지 않고, 호출자가 이미 계산한 `isError`/`isSuccess`
/// 플래그와 캡션(문구·색)을 값으로 받는다. **캡션 문구 자체는 화면마다 다를 수 있다**(온보딩 톤 vs 마이페이지 톤 —
/// 의도적으로 다르게 유지되어 온 워딩, 1:1 동기화 요구 아님) — 그래서 텍스트를 컴포넌트가 하드코딩하지 않는다.
///
/// **글자수 제한 트랩을 여기 한 곳에서만 처리한다** — `text` 바인딩에 직접 물리면(로컬 완충 없이) clamp 후
/// `get`이 SwiftUI가 방금 그 필드에 써준 값과 같아져 "변화 없음"으로 판단되고, 네이티브 텍스트필드가 초과
/// 입력을 화면에 그대로 들고 있게 된다. 내부 `fieldText`(로컬 `@State`)에서 clamp한 뒤 `text`로 반영하는
/// 2단계로 처리해 호출자가 이 함정을 각자 다시 구현할 필요가 없게 했다.
public struct WSSNicknameField: View {

    public struct Caption: Equatable {
        public let text: String
        public let color: Color

        public init(text: String, color: Color) {
            self.text = text
            self.color = color
        }
    }

    @Binding private var text: String
    @State private var fieldText: String
    private let isFocused: FocusState<Bool>.Binding

    private let placeholder: String
    private let maxLength: Int
    private let isError: Bool
    private let isSuccess: Bool
    private let caption: Caption?
    private let showsCharacterCount: Bool
    private let isDuplicationCheckEnabled: Bool
    private let isCheckingDuplication: Bool
    private let onCheckDuplication: () -> Void

    /// - Parameters:
    ///   - text: 확정된(이미 도메인 쪽 clamp를 거친) 닉네임 값. 필드 내부 편집은 로컬 버퍼를 거쳐 이
    ///     바인딩으로 반영된다.
    ///   - isFocused: 호출자가 소유한 `@FocusState`를 그대로 넘긴다(`$isKeyboardFocused` 형태) — 컴포넌트가
    ///     자체 포커스 상태를 갖지 않는 이유는, 호출자가 "필드 바깥 탭하면 키보드 내리기"(`MyPageEditView`처럼
    ///     같은 화면의 다른 텍스트필드와 포커스를 공유하는 경우 포함)를 그대로 제어할 수 있어야 해서다.
    ///   - isError: 공백·형식오류·중복 등 사용자가 고쳐야 하는 상태(호출자가 도메인 검증 상태로 판단).
    ///   - isSuccess: 중복확인 통과(사용 가능) 상태.
    ///   - caption: 검증 상태에 대응하는 문구+색(문구는 화면마다 다를 수 있어 호출자가 결정).
    ///   - showsCharacterCount: 글자수 카운터(`n / maxLength`) 노출 여부 — 마이페이지는 켜고 온보딩은 끈다.
    ///   - onCheckDuplication: "중복확인" 탭 시 발화.
    public init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        placeholder: String = "닉네임",
        maxLength: Int,
        isError: Bool,
        isSuccess: Bool,
        caption: Caption?,
        showsCharacterCount: Bool = false,
        isDuplicationCheckEnabled: Bool,
        isCheckingDuplication: Bool,
        onCheckDuplication: @escaping () -> Void
    ) {
        self._text = text
        self._fieldText = State(initialValue: text.wrappedValue)
        self.isFocused = isFocused
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.isError = isError
        self.isSuccess = isSuccess
        self.caption = caption
        self.showsCharacterCount = showsCharacterCount
        self.isDuplicationCheckEnabled = isDuplicationCheckEnabled
        self.isCheckingDuplication = isCheckingDuplication
        self.onCheckDuplication = onCheckDuplication
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                fieldBox
                duplicateCheckButton
            }

            Spacer().frame(height: 4)

            footerRow
        }
        .onChange(of: fieldText) { _, newValue in
            let clamped = String(newValue.prefix(maxLength))
            if clamped != newValue {
                fieldText = clamped
                return
            }
            text = clamped
        }
        .onChange(of: text) { _, newValue in
            guard fieldText != newValue else { return }
            fieldText = newValue
        }
    }
}

// MARK: - Sections

private extension WSSNicknameField {
    var fieldBox: some View {
        HStack(spacing: 0) {
            TextField(placeholder, text: $fieldText)
                .padding(.vertical, 10.5)
                .padding(.leading, 12)
                .applyWSSFont(.body2)
                .foregroundStyle(Color.wssBlack)
                .tint(Color.wssBlack)
                .focused(isFocused)

            if !fieldText.isEmpty {
                Button {
                    fieldText = ""
                } label: {
                    trailingIcon
                        .frame(width: 44, height: 44)
                }
            }
        }
        .background(isFocused.wrappedValue ? Color.wssWhite : Color.wssGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor ?? .clear, lineWidth: 1)
        )
    }

    /// 검증 성공이면 성공 체크, 에러면 실패 표시, 그 외(입력 전·확인 대기·미변경)엔 기본 지우기 X —
    /// 탭하면 상태와 무관하게 항상 지워진다(같은 버튼, 아이콘만 상태에 따라 교체).
    var trailingIcon: some View {
        Group {
            if isSuccess {
                WSSImage.icNicknameSuccess.swiftUIImage
                    .resizable()
                    .scaledToFit()
            } else if isError {
                WSSImage.icNicknameFailed.swiftUIImage
                    .resizable()
                    .scaledToFit()
            } else {
                WSSImage.icCancel.swiftUIImage
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 18, height: 18)
        .animation(.easeInOut(duration: 0.1), value: isSuccess)
        .animation(.easeInOut(duration: 0.1), value: isError)
    }

    /// 에러=secondary100, 성공(사용 가능)=primary100, 그 외(입력 전·미변경·확인 대기)엔 테두리 없음.
    var borderColor: Color? {
        if isError { return Color.wssSecondary100 }
        if isSuccess { return Color.wssPrimary100 }
        if isFocused.wrappedValue { return Color.wssGray70 }
        return nil
    }

    /// 호출자가 넘긴 `isDuplicationCheckEnabled`에만 반응한다(예: "새 닉네임을 입력했고 아직 에러 없이
    /// 확인이 필요한" 상태 — 그 판단은 도메인을 아는 호출자 몫).
    var duplicateCheckButton: some View {
        Button(action: onCheckDuplication) {
            Group {
                if isCheckingDuplication {
                    ProgressView()
                } else {
                    Text("중복확인")
                        .applyWSSFont(.body2)
                        .foregroundStyle(isDuplicationCheckEnabled ? Color.wssPrimary100 : Color.wssGray200)
                }
            }
            .frame(width: 88, height: 44)
            .background(isDuplicationCheckEnabled ? Color.wssPrimary50 : Color.wssGray70)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isDuplicationCheckEnabled)
    }

    var footerRow: some View {
        HStack(spacing: 0) {
            if let caption {
                Text(caption.text)
                    .applyWSSFont(.body2)
                    .foregroundStyle(caption.color)
            }

            Spacer()

            if showsCharacterCount {
                Text("\(fieldText.count)")
                    .foregroundStyle(Color.wssGray300)
                Text(" / \(maxLength)")
                    .foregroundStyle(Color.wssGray200)
            }
        }
        .applyWSSFont(.body4)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: 24) {
        WSSNicknameField(
            text: .constant(""),
            isFocused: $isFocused,
            maxLength: 10,
            isError: false,
            isSuccess: false,
            caption: nil,
            isDuplicationCheckEnabled: false,
            isCheckingDuplication: false,
            onCheckDuplication: {}
        )

        WSSNicknameField(
            text: .constant("tester"),
            isFocused: $isFocused,
            maxLength: 10,
            isError: false,
            isSuccess: true,
            caption: .init(text: "사용 가능한 닉네임이에요", color: Color.wssPrimary100),
            showsCharacterCount: true,
            isDuplicationCheckEnabled: false,
            isCheckingDuplication: false,
            onCheckDuplication: {}
        )

        WSSNicknameField(
            text: .constant("1tester"),
            isFocused: $isFocused,
            maxLength: 10,
            isError: true,
            isSuccess: false,
            caption: .init(text: "이미 사용 중인 닉네임이에요", color: Color.wssSecondary100),
            showsCharacterCount: true,
            isDuplicationCheckEnabled: false,
            isCheckingDuplication: false,
            onCheckDuplication: {}
        )
    }
    .padding(.horizontal, 20)
}
