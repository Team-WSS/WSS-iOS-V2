# Definition of Done

작업을 "완료"로 부르기 전 만족해야 할 기준. 에이전트는 끝내기 전 이 목록을 스스로 점검한다.

## 모든 작업 공통

- [ ] 의존성 방향 위반 없음 (`App→Feature→(UI/Domain)←Data→Core`). 역방향 import 금지.
- [ ] 레이어 비동기/상태 규칙 준수 (Domain/Data = async/await, Feature = SwiftUI Observation/`@Observable`, UI/App = 순수 SwiftUI).
- [ ] 변경 영향 받는 **가장 가까운 가이드(`CLAUDE.md`) 갱신** (책임/시나리오/주의사항). 함정 발견 시 `/learn`.
- [ ] 코드와 문서가 일치 (불일치면 코드 기준으로 문서 수정).

## 새 모듈 추가 시

- [ ] [WORKFLOW.md](WORKFLOW.md)의 "새 모듈 추가 절차" 6단계 완료 (레지스트리 등록 ~ 모듈 가이드 작성).

## Domain 작업 시 (테스트 필수)

- [ ] 판단하는 코드(분기·검증·계산이 있는 Entity·정책·UseCase)에 **테스트 작성** — 목록을 먼저 합의 ([docs/TESTING.md](TESTING.md) 작업 순서).
- [ ] 경계값은 "딱 그 값"과 "하나 넘는 값"을 둘 다, 에러는 case마다 `#expect(throws:)`.
- [ ] ArchLint 통과 + 테스트 이름을 바꿨으면 `TEST_SPEC.md` 갱신(`ArchLint --write-test-specs`).
- [ ] 뮤테이션 도구(`Mutate <모듈>`)의 살아남은 버그를 확인하고 판단을 PR에 남김.
- [ ] 프로토콜/시그니처를 바꿨다면 **같은 PR에서 Mock·테스트 동기화** (drift 방지).

## Data 작업 시

- [ ] 에러 변환 규칙 준수 ([docs/CONVENTIONS.md](CONVENTIONS.md) 변환표), 전 catch 분기 로깅.
- [ ] 외부 노출 생성은 `XxxFactory` 경유.

## 마무리

- [ ] 브랜치 `Type/#이슈`, 커밋 `[Type] #이슈 - 한글 설명`.
- [ ] 머지는 PR 경유 (develop 직접 push 금지).
