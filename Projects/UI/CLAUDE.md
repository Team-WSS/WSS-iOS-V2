# UI 레이어

화면을 직접 만드는 레이어가 아니라, **Feature가 UI를 구현할 때 쓰는 재사용 헬퍼/컴포넌트** 모음.

- 모듈 식별자: `ModuleType.ui(.xxx)` → 모듈명 suffix 없음
- 디렉토리: `Projects/UI/<Module>/`
- 비동기/상태: SwiftUI + Combine 계열

## 모듈

| 모듈 | 책임 |
|---|---|
| `DesignSystem` | 색상·타이포·간격 등 디자인 토큰, 공통 스타일 |
| `WSSComponent` | 웹소소 공용 SwiftUI 컴포넌트 (버튼, 카드 등) |

> ⚠️ `wssComponent` 케이스의 모듈명은 `WSSComponent` 로 강제 매핑됨 (ModuleType.swift의 `UIModule.name` 참고).

## 의존 규칙

- ✅ 다른 UI 모듈, `Core`(필요 시), SwiftUI.
- ❌ Domain / Data import 금지. **비즈니스 로직·도메인 Entity를 알지 않는다.**
  화면에 무엇을 그릴지는 Feature가 Entity → 표시용 모델로 가공해 전달한다.
- ❌ Feature / App import 금지 (하위가 상위를 모른다).

## 코드 규칙

- 순수 표현(presentation) 컴포넌트. 네트워크·저장·도메인 정책 금지.
- 입력은 값/콜백으로 받는다. 컴포넌트가 도메인 타입에 직접 의존하지 않게 한다.
- `Resources/`, `Demo/` 타깃으로 단독 미리보기·검증.

## 주의사항 (작업 중 발견 시 누적)

- (없음 — 발견 시 추가)
