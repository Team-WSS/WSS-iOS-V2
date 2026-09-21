<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# Logger

로깅 추상화. 다른 레이어는 이 프로토콜에만 의존한다.

- 식별자: `ModuleType.core(.logger)` / 의존: 없음

## 핵심 구조

- `Logger` 프로토콜: `debug` / `info` / `error`.
- 구현체: `ConsoleLogger`, `OSLogger`.
- Data 레이어의 `DataLogger`(BaseData)가 이 `Logger`를 underlying으로 감싼다.

## 주의사항 (작업 중 발견 시 누적)

- 특이사항 없음.
