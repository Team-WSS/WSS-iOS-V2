<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SocialData

`SocialDomain.SocialRepository` 구현 — 차단 + 신고.

- 식별자: `ModuleType.data(.social)` / 의존: `SocialDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SocialDataFactory.makeSocialRepository(client:logger:)` — 다른 Data 모듈과 동일하게 `DataLogger?`를 직접 받는다(호출부가 `DataLogger(moduleName: "SocialData", underlying:)`를 조립해 넘김).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`BlockUserQuery`의 필드명은 `userId`(Swift 관례상 `userID`가 아니라)여야 한다** — `QueryItemConvertible`이 `JSONEncoder` 기본 설정(키 변환 없음)으로 프로퍼티명을 그대로 쿼리 키로 쓰기 때문에, `userID`로 두면 서버가 기대하는 `userId`가 아니라 `?userID=`로 나가 조용히 실패한다(#172에서 발견·수정). 다른 모듈의 쿼리 DTO(`GetUserFeedsQuery.lastFeedId`, `UserLibraryQuery.lastUserNovelId` 등)도 전부 `Id`(소문자 d)로 통일돼 있으니 새 쿼리 필드를 추가할 때 이 관례를 따를 것.
