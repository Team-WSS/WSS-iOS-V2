<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# CommentData

`CommentDomain.CommentRepository`의 네트워크 구현. 표준 패턴(Service→Repository→Mapper) 그대로.

- 식별자: `ModuleType.data(.comment)` / 의존: `CommentDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `CommentDataFactory.makeRepository(client:logger:)`

## 주의사항 (작업 중 발견 시 누적)

- 특이사항 없음. 레이어 표준 규칙(Projects/Data/AGENTS.md)만 따르면 됨.
