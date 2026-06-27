# 커밋·브랜치 Type 표 (WSS-iOS-V2)

`commit` · `commit-staged` · `commit-all` 스킬이 공유하는 **단일 Type 집합**.
여기 없는 Type은 절대 만들지 않는다. 변경 성격에 가장 맞는 **하나**를 고른다.

- 커밋 헤더에서는 대괄호로 감싼다 → `[Feat]`, `[Fix]` … (양식: `[Type] #이슈 - 내용`)
- 브랜치명에서는 대괄호 없이 → `<Type>/#번호` (예: `Feat/#132`)

| Type | 언제 |
|---|---|
| `Design` | 뷰 레이아웃·UI 구조 작업 |
| `Feat` | 새로운 기능 구현 |
| `Network` | 네트워크 연결·API 통신 |
| `Add` | Feat 이외의 부수적인 코드 추가, 라이브러리 추가, 새 View 생성 |
| `Del` | 쓸모없는 코드·주석 삭제 |
| `Fix` | 버그·오류 해결, 코드 수정 |
| `Refactor` | 전면 수정 |
| `Chore` | 그 이외 자잘한 작업 |
| `Docs` | README 등 문서 개정 |
| `Setting` | 프로젝트·환경 세팅 |
| `Test` | 테스트 코드 |
| `Merge` | 브랜치 병합 |

- 어느 Type이 맞을지 애매하면 `git log --oneline -8`에서 유사 변경에 쓰인 Type을 참고한다.
- 전역 `commit` 스킬 표에는 `[AD]`(광고)가 있으나 이 프로젝트에서는 제외한다.
- `new-issue` 커맨드(`.claude/commands/new-issue.md`)와 그 스크립트(`.claude/scripts/new-issue.sh`)도 이 파일을 쓴다. **스크립트는 실행 시 이 표를 직접 파싱**해 `ALLOWED_TYPES`를 만든다 → Type 추가·변경은 **이 파일만** 고치면 모든 곳에 자동 반영된다(수동 동기화 불필요).
- ⚠️ 단, 표 행 형식 `` | `Type` | 설명 | `` 를 유지할 것 — 스크립트 파싱이 "백틱으로 감싼 첫 칼럼"에 의존한다. 형식이 깨지면 스크립트가 즉시 중단(fail-loud)한다.
