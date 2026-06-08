<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelData

`NovelDomain.NovelRepository`의 네트워크 구현. 구성요소는 `Sources/`를 직접 보면 된다.
여기엔 **코드만 봐선 모르는 것**만 적는다.

- 식별자: `ModuleType.data(.novel)` / 의존: `NovelDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `NovelDataFactory.makeNovelRepository(client:appStorage:logger:)` (상위는 이 Factory만 안다)

## 핵심 시나리오

- **상세 조회(`fetchNovel`)**: basic + detail **네트워크 2회** 호출 후 `NovelMapper.novelInformation(...)`로 합성.
- **검색**: text → `NormalSearchQuery`, filter → `NovelMapper.detailSearchQuery`로 변환해 호출.
- **서재/통계**: `appStorage.get(.userID)`로 로그인 사용자 ID를 읽어 쿼리에 사용.

## 주의사항 (작업 중 발견 시 누적)

- `fetchNovel`은 2회 호출 → **하나라도 실패하면 전체 실패**.
- userID 부재 시 `?? 0` fallback — 비로그인 흐름 동작 확인 필요.
- 에러 변환은 레이어 고정 규칙을 따름 (`NetworkingError`→`toRepositoryError()`, `MappingError`→`.invalidData`, 그 외 `.unknown`, 전 분기 로깅).
