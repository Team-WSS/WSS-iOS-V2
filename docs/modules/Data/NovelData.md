# NovelData

- **레이어**: Data → 규칙은 [../../layers/Data.md](../../layers/Data.md)
- **식별자**: `ModuleType.data(.novel)`
- **위치**: `Projects/Data/NovelData/`
- **한 줄 책임**: `NovelDomain.NovelRepository`의 네트워크 구현 — 작품 API 연동·DTO 매핑.

## 의존성

- internal: `NovelDomain`, `BaseDomain`, `BaseData`, `Networking`(Core), `Logger`(Core)
- external: 없음

## 주요 구성요소

| 종류 | 이름 | 역할 |
|---|---|---|
| Repository | `DefaultNovelRepository` | `NovelRepository` 구현. Service 호출 → Mapper 변환 → 에러/로깅 |
| Service | `NovelService` / `DefaultNovelService` | 작품 API 호출 (basic/detail/search/library/interest/stats) |
| Mapper | `NovelMapper` | Response(DTO) → Domain Entity, Filter → Query 변환 |
| Endpoint | `NovelEndPoint` | 경로·HTTP 메서드 정의 |
| Factory | `NovelDataFactory` | `makeNovelRepository(client:appStorage:logger:)` 조립 진입점 |
| Logger | `NovelAction` | 액션별 로그 식별자 |
| DTO | `Response/*`, `Query/*` | 서버 응답 / 요청 쿼리 모델 |

## 핵심 동작 / 시나리오

- **조립**: 상위 레이어는 `NovelDataFactory.makeNovelRepository(...)`만 호출 → `NovelRepository` 타입 수신.
  (내부에서 `DefaultNovelService` + `UserDefaultsStorage` 구성)
- **상세 조회**: `fetchNovel` → basic+detail 2회 호출 후 `NovelMapper.novelInformation(...)`로 합성.
- **검색**: text → `NormalSearchQuery`, filter → `NovelMapper.detailSearchQuery`로 변환해 호출, `searchNovels`로 매핑.
- **서재/통계**: `AppStorage`에서 `userID`를 읽어 쿼리에 사용 (`appStorage.get(.userID)`).
- **에러 변환(고정 규칙)**: `NetworkingError → toRepositoryError()`, `MappingError → .invalidData`, 그 외 `.unknown`. 모든 분기 로깅.

## 주의사항 (작업 중 발견 시 누적)

- `fetchNovel`은 네트워크 2회(basic, detail) → 둘 중 하나라도 실패 시 전체 실패.
- userID 부재 시 `?? 0` fallback 사용 — 비로그인 흐름에서 동작 확인 필요.
