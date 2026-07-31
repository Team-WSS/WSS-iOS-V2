# UI 레이어

화면을 직접 만드는 레이어가 아니라, **Feature가 UI를 구현할 때 쓰는 재사용 헬퍼/컴포넌트** 모음.

- 모듈 식별자: `ModuleType.ui(.xxx)` → 모듈명 suffix 없음
- 디렉토리: `Projects/UI/<Module>/`
- 비동기/상태: 순수 SwiftUI 표현 컴포넌트 (값/콜백 입력)

## 모듈

| 모듈 | 책임 |
|---|---|
| `DesignSystem` | 색상·타이포·간격 등 디자인 토큰, 공통 스타일 |
| `WSSComponent` | 웹소소 공용 SwiftUI 컴포넌트 (버튼, 카드 등) |

> ⚠️ `wssComponent` 케이스의 모듈명은 `WSSComponent` 로 강제 매핑됨 (ModuleType.swift의 `UIModule.name` 참고).

## 의존 규칙

- ✅ 다른 UI 모듈, `Core`(필요 시), SwiftUI. `BaseDomain` 공통 값 타입은 **표현 매핑 목적에 한해** 허용(예: `WSSComponent`의 `DomainPresentation` 확장).
- ❌ Data import 금지. Domain도 `BaseDomain` 외(Entity/Repository)는 금지 — **비즈니스 로직·상위 도메인 모델을 알지 않는다.**
  화면에 무엇을 그릴지는 Feature가 Entity → 표시용 모델로 가공해 전달한다.
- ❌ Feature / App import 금지 (하위가 상위를 모른다).

## 코드 규칙

- 순수 표현(presentation) 컴포넌트. 네트워크·저장·도메인 정책 금지.
  - **예외 — URL 기반 이미지 로딩은 표현 인프라로 보고 허용한다**(`WSSAsyncImage`, SwiftUI `AsyncImage`).
    **값으로 받은 URL에서 바이트만 읽을 뿐, 앱의 네트워킹 스택(`Core/Networking`)·엔드포인트·인증·에러 타입을 알지 않는다**는 선은 지킨다
    (`WSSComponent`는 `Core/Networking`에 의존하지 않는다 — `Project.swift` 확인). 이미지 로딩을 Feature로 올리면
    화면마다 prefetch를 손으로 짜게 되어(구 `NovelDetailView`) 중복이 되살아나므로 컴포넌트에 두는 편이 낫다.
  - ⚠️ **이 예외로 못 덮는 순간이 온다 — 인증 헤더가 필요한 이미지가 생기면** `URLSession.shared` 직행으로는 안 되니
    그때는 로더 주입(상위가 로딩 결과·로더를 내려주는) 구조로 전환할 것. 예외를 넓혀 토큰·헤더를 UI에 들이지 말 것.
  - **예외 — 시스템 제스처 복구(`enableSwipeBack`)도 표현 인프라로 본다.** 네비바를 숨기면 iOS가 함께 꺼버리는
    스와이프 뒤로가기를 **원래대로 되돌리는 것뿐**이고, 어디로 가는지(라우팅·화면 스택 구성)는 여전히 Feature/App의 몫이다.
    ⚠️ 여기서 **"어느 화면으로 이동"까지 UI가 정하기 시작하면 선을 넘는 것** — 내비게이션 정책은 올리지 말 것.
    이 예외가 필요한 이유는 [WSSComponent](WSSComponent/CLAUDE.md)의 같은 항목 참고(복제본이 갈라져 사고가 났다).
- 입력은 값/콜백으로 받는 것이 기본. `BaseDomain` 공통 값 타입만 `DomainPresentation` 매핑 목적에 한해 직접 사용하고, 그 외 도메인 타입에는 의존하지 않는다.
- `Resources/`, `Demo/` 타깃으로 단독 미리보기·검증.

## 주의사항 (작업 중 발견 시 누적)

- (없음 — 발견 시 추가)
