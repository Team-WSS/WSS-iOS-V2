<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SocialData

`SocialDomain.SocialRepository` 구현 — 차단 + 신고.

- 식별자: `ModuleType.data(.social)` / 의존: `SocialDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SocialDataFactory.makeSocialRepository(client:logger:)` — 다른 Data 모듈과 동일하게 `DataLogger?`를 직접 받는다(호출부가 `DataLogger(moduleName: "SocialData", underlying:)`를 조립해 넘김).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`BlockUserQuery`의 필드명은 `userId`(Swift 관례상 `userID`가 아니라)여야 한다** — `QueryItemConvertible`이 `JSONEncoder` 기본 설정(키 변환 없음)으로 프로퍼티명을 그대로 쿼리 키로 쓰기 때문에, `userID`로 두면 서버가 기대하는 `userId`가 아니라 `?userID=`로 나가 조용히 실패한다(#172에서 발견·수정). 다른 모듈의 쿼리 DTO(`GetUserFeedsQuery.lastFeedId`, `UserLibraryQuery.lastUserNovelId` 등)도 전부 `Id`(소문자 d)로 통일돼 있으니 새 쿼리 필드를 추가할 때 이 관례를 따를 것.
- **신고 4메서드(`reportSpoilerFeed`/`reportImproperFeed`/`reportSpoilerComment`/`reportImproperComment`)는
  이미 신고한 경우(서버 `REPORT-002`/`REPORT-004`)를 `RepositoryError.alreadyReported`로 개별 매핑한다**
  (#255 QA, `ProfileData`의 `USER-018`/`USER-015` 선례와 동일 `if case .responseFailure(_, let body) = error,
  body?.code == "..."` 패턴). 이 스펙은 `api-spec` 스킴의 OpenAPI 문서엔 없다(신고 엔드포인트가 15개
  문서화 목록에 없음) — 실제 코드는 사용자가 dev 서버에서 중복 신고를 재현해 확인한 값이다. 새 신고
  관련 서버 에러 코드가 필요해지면 문서보다 이 방식(실측 확인)을 우선할 것. `DefaultSocialRepositoryTests`에
  4메서드 모두 `NetworkingError.responseFailure(code:409, body: ErrorResponse(code:"REPORT-00X", ...))` →
  `RepositoryError.alreadyReported` 커버리지가 있다(#255 리뷰 Nit 반영 — 이 패턴을 처음 쓴 `ProfileData`의
  `USER-015`/`USER-018`엔 아직 이런 개별 테스트가 없다, 새로 그쪽을 만질 땐 같이 채울지 고려할 것).
