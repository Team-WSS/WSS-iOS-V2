<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/UI/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
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
- **아이콘 SVG는 원색 고정**(예: `icNavigateLeft`/`icThreedots`는 연회색 #C7C7D0) — 다른 색이 필요하면 호출부에서 `renderingMode(.template)` + `foregroundStyle`로 입힌다. 밝은 배경 위에 원색 그대로 쓰면 안 보일 수 있다.
- Figma에서 노드 SVG를 export하면 **부모 프레임 배경 rect가 딸려 온다** — xcassets에 넣기 전에 아이콘 path만 남기고 제거할 것(#154 에셋 추가에서 겪음).
- 폰트는 raw `.font()` 대신 반드시 `applyWSSFont` 사용 (lineHeight/자간까지 일관 적용).
- ⚠️ **`.underline()`/`.strikethrough()`는 raw `Text`에 *먼저* 걸어야 한다** — `Text(x).underline()`(Text 메서드 → Text)로 밑줄을 텍스트에 baked-in 한 뒤 `.applyWSSFont(...)`/`.foregroundStyle(...)`을 붙인다. `applyWSSFont`는 `View` 확장이라 그 뒤(=`some View` 단계)에 `.underline()`을 걸면 **컴파일은 되지만**(View용 오버로드) `WSSFontViewModifier`의 `.font()`/`.kerning()` 렌더에 밑줄이 안 붙어 **조용히 안 보인다**. (NovelDetail 헤더 작가 이름 밑줄에서 겪음.)
