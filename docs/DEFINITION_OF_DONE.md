# Definition of Done

작업을 "완료"로 부르기 전 만족해야 할 기준. 에이전트는 끝내기 전 이 목록을 스스로 점검한다.

## 모든 작업 공통

- [ ] 의존성 방향 위반 없음 (`App→Feature→(UI/Domain)←Data→Core`). 역방향 import 금지.
- [ ] 레이어 비동기/상태 규칙 준수 (Domain/Data = async/await, Feature = SwiftUI Observation/`@Observable`, UI/App = 순수 SwiftUI).
- [ ] 변경 영향 받는 **가장 가까운 가이드(`CLAUDE.md`) 갱신** (책임/시나리오/주의사항). 함정 발견 시 `/learn`.
- [ ] 코드와 문서가 일치 (불일치면 코드 기준으로 문서 수정).

## 새 모듈 추가 시

- [ ] `ModuleType.swift`에 case 등록 (단일 진실 소스).
- [ ] `Project.swift` 템플릿으로 작성 + `internalDependencies` 선언.
- [ ] `tuist generate` 실행해 프로젝트 반영.
- [ ] `docs/MODULE_GUIDE_TEMPLATE.md` 복사해 모듈 `CLAUDE.md` 작성.

## Domain 작업 시 (테스트 필수)

- [ ] 새 UseCase·Entity·정책에 **테스트 작성** ([docs/TESTING.md](TESTING.md) 규약).
- [ ] 커버리지 4종 고려: 정상 / 경계값 / 정책 위반 / 상태 변화.
- [ ] 프로토콜/시그니처를 바꿨다면 **같은 PR에서 Mock·테스트 동기화** (drift 방지).
- [ ] CI(`/domain-test`) 매트릭스를 깨는 빈/잔재 폴더를 남기지 않음.

## Data 작업 시

- [ ] 에러 변환 규칙 준수 ([docs/CONVENTIONS.md](CONVENTIONS.md) 변환표), 전 catch 분기 로깅.
- [ ] 외부 노출 생성은 `XxxFactory` 경유.

## 마무리

- [ ] 브랜치 `Type/#이슈`, 커밋 `[Type] #이슈 - 한글 설명`.
- [ ] 머지는 PR 경유 (develop 직접 push 금지).
