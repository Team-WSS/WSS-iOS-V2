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

- **작품 상세 응답의 `novelGenres`는 배열이 아니라 `/`로 이은 한 문자열**(`"로맨스/로판"`)이다 — `author`가 콤마 문자열인 것과 **구분자가 다르다**. DTO를 `[String]`으로 두면 디코딩이 통째로 실패해 화면이 "네트워크 연결 실패"로 뜬다(실제 원인은 `.invalidData`라 원인 찾기 어렵다). Mapper가 `/`로 쪼개 `NovelGenre`로 매핑하고, UI는 반대로 `displayName`을 `/`로 이어 되돌린다.
- **`novelImage`(표지)와 `novelGenreImage`(장르 아이콘 경로, 예 `/icGenre/BL`)는 다른 필드**다 — 상세 매핑이 표지에 `novelGenreImage`를 넣고 있었다(#154에서 수정). 검색·서재 매퍼는 처음부터 `novelImage`를 쓴다.
- **이미지 필드(표지 `novelImage`·`platformImage`)는 버킷 상대 경로로 올 수 있다** — `URL(string:)` 직조립 금지, `ImageURLResolver.resolve(from:)`(BaseData) 경유(full URL/경로 혼재를 흡수하고 경로엔 `@{scale}x.png`를 붙인다). 표지 3곳(서재·상세·검색)과 `platformImage` 모두 경유 완료. ⚠️ 단 `platformUrl`(플랫폼 사이트 주소)은 **이미지가 아니라 외부 링크**라 resolver 대상이 아니다 — `URL(string:)` 유지(실패 시 `MappingError.invalidPlatformUrl` throw).
- **`Novel.isInterested`는 nil = "비로그인" 의미** — 매퍼가 이 인자를 안 넘기면 기본값 nil이 되어 관심 버튼이 **에러·로그 없이 no-op**이 된다(엔티티 정책 + VM 가드가 조용히 스킵). `basicDTO.isUserNovelInterest` 매핑 필수(#154에서 수정).
- **작품 상세 조회(`getNovelBasicInfo`/`getNovelDetailInfo`)의 토큰 정책은 `.usesTokenIfAvailable`** — 공개 화면이라 `.withoutToken`으로 두기 쉽지만, 응답에 유저별 필드(관심·읽기 상태·내 별점·시작/종료일)가 있어 토큰이 없으면 **항상 익명 값**이 온다(실서버에서 내 평가·관심이 안 뜨는 증상 — #154에서 수정).
- **일반 검색(`getNormalSearchResult`)도 같은 이유로 `.usesTokenIfAvailable`**(#165에서 `.withoutToken` → 수정) — 비로그인도 검색은 되지만, 토큰이 없으면 서버가 요청을 익명으로 봐서 `SearchDomain`이 기대하는 "검색 실행 시 서버 자동 기록"(최근 검색어)이 로그인 유저에게 남지 않았다. `SearchNovelResponse`엔 애초에 `isInterested` 필드가 없어(토큰을 보내도) 검색 결과 카드의 관심 여부는 여전히 반영 안 됨 — 별개 갭, 필요해지면 서버 응답에 필드 추가 여부부터 확인.
- **`userReview`의 매력포인트·키워드는 `[]`로 둔다** — 유저 본인 선택값이 이 응답에 없어서다. `detailDTO.attractivePoints`(독자 전체 집계값)를 채워 넣지 말 것 — 과거에 그렇게 돼 있었고(미소비 필드라 실동작 영향은 없었음) #154에서 `[]`로 정리했다. 본인 선택값이 필요해지면 유저별 API에서 받아야 한다.
- `fetchNovel`은 2회 호출 → **하나라도 실패하면 전체 실패**.
- userID 부재 시 `?? 0` fallback — 비로그인 흐름 동작 확인 필요.
- 에러 변환은 레이어 고정 규칙을 따름 (`NetworkingError`→`toRepositoryError()`, `MappingError`→`.invalidData`, 그 외 `.unknown`, 전 분기 로깅).
