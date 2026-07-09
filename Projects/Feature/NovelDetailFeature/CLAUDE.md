<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDetailFeature

소설 상세(NovelDetail) 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.novelDetail)` / 의존: **전용 `NovelDetailDomain`은 없고 `NovelDomain`을 쓴다**(#154 명세)
- 진입점: `NovelDetailFactory` (골격은 구현 단계에서 확정)

## 핵심 시나리오

- (구현 후 채운다)

## 주의사항 (작업 중 발견 시 누적)

- 대응 `NovelDetailDomain`이 없다 — UseCase는 `NovelDomain` 것을 주입받는다. `new-module` 기본 추론(`domain(.<같은이름>)`)과 다른 지점.
