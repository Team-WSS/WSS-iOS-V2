<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/UI/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# DesignSystem

디자인 토큰 — 색상 / 폰트 / 이미지. 모든 UI·Feature의 시각 기반.

- 식별자: `ModuleType.ui(.designSystem)` / 의존: SwiftUI, UIKit
- 리소스는 `Resources/`의 `.xcassets` (Tuist가 접근자 자동 생성)

## 핵심 사용법

- **색상**: `Color.wssPrimary100`, `Color.wssGray70`, 장르별 `Color.romanceBlock`/`romanceLink` 등. (`WSSColor` = 생성된 `DesignSystemAsset.Colors`의 typealias)
- **폰트**: `someView.applyWSSFont(.title1)` 식. `WSSFontStyle`이 size/lineHeight/letterSpacing을 정의하고 ViewModifier가 적용.
- **이미지**: `WSSImage`.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ 색상/이미지 접근자는 **Tuist 리소스 합성으로 생성**된다(`DesignSystemAsset`). 에셋 추가 후 `tuist generate` 안 하면 접근자가 없어 빌드 실패.
- 새 색은 `.xcassets`에 추가 + `WSSColor.swift`의 `Color` extension에 토큰 추가, 두 곳 모두 갱신.
- 폰트는 raw `.font()` 대신 반드시 `applyWSSFont` 사용 (lineHeight/자간까지 일관 적용).
