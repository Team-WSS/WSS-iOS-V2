# V1 ↔ V2 서버 요청 파라미터 매핑 비교 (축 C / C2)

> 이슈 **#222** · 2026-08-28 작성. C1(동작 계약)에서 각 Feature 모듈 `V1_BEHAVIOR_CONTRACT.md`의
> **`부록 A — 서버 요청 파라미터 매핑`**을 재료로, V1↔V2가 **서버에 실제로 무엇을 보내는지**를 교차 종합해
> 불일치(필드명·전송 조건·값/토큰·대소문자)를 목록화한 문서.
>
> - **V1** = Team-WSS/WSS-iOS (UIKit·RxSwift), 형제 클론 `../WSS-iOS` @ `eefcb9b2`.
> - **V2** = 현재 레포.
> - 각 항목의 근거·행별 상세는 해당 모듈 계약서 `부록 A`가 정본이다(여기서 중복하지 않는다). 이 문서는
>   **교차 종합 + 위험 판정**만 담는다.

---

## 직렬화 규칙 (모든 판정의 전제)

`Core/Networking`의 `QueryItemConvertible.asQueryItems()`(`Encodable → JSON → [URLQueryItem]`):

| 값 종류 | 직렬화 | 함의 |
|---|---|---|
| **Optional `nil`** | NSNull → **쿼리에서 제외** | 미적용 필터는 `Optional`로 두고 nil이면 파라미터 자체가 안 나간다. |
| **`Bool`(non-optional)** | **항상** `"true"`/`"false"` | non-optional Bool은 "미선택"을 표현할 수 없다 → 조건부 필터를 non-optional Bool로 두면 **항상 전송**된다(=`isCompleted` 회귀의 근본 원인). |
| **배열** | 요소 콤마 join. **빈 배열 → `?key=`(빈 값)** | 빈 배열은 생략이 아니라 **빈 문자열 전송**. 서버가 이를 `[""]` 필터로 오해할 수 있다(`UserLibraryV2Query` 주석이 명시). |
| **그 외(Int/String)** | `String(describing:)` | 열거형 `rawValue`를 그대로 실으면 **Swift case 이름의 대소문자**가 그대로 서버로 간다(→ 피드 정렬 대소문자 불일치). |

**→ C2 위험의 두 축**: ① 조건부 필터를 non-optional로 둬 **항상 전송**되는가, ② `rawValue`를 그대로 실어
**서버 토큰의 대소문자/철자와 어긋나는가**.

---

## 0. 판정·확인이 필요한 항목 (결론 요약)

| # | 항목 | 모듈 | 심각도 | 상태 | 조치 |
|---|---|---|---|---|---|
| 1 | **검색 `isCompleted` 항상 전송** — 미선택도 `false`로 나가 완결작 90% 누락 | Search | 🔴 확정 회귀 | 실서버 검증됨(2026-08-28) | `Bool?`로 전환(Library 방식) → **TODO §9** |
| 2 | **내 피드 정렬 대소문자 불일치** — V1 `RECENT`/`OLD`(대문자) vs V2 `recent`/`old`(소문자) | Feed | 🟠 회귀 유력 | **본 C2에서 신규 발견** · 서버 대소문자 민감도 미확인 | 서버 확인 → 민감하면 `.uppercased()`(타 모듈과 동일) |
| 3 | **탈퇴 body `refreshToken` 제거** — V1 `{reason,refreshToken}` vs V2 `{reason}` | Setting | 🟡 백엔드 확인 | 계약서 §0-1 | 백엔드 V2 스펙이 body refreshToken 불요구인지 확인 |
| 4 | **검색 필터 빈 배열 `?key=` 빈값 전송** — `genres`/`platformNames`/`keywordIds`가 non-optional 배열 | Search | 🟡 검증 권장 | Library는 `Optional`로 생략(대조됨) | 서버가 빈 값을 무필터로 관용하는지 확인 or `Optional`화 |
| 5 | **플랫폼 서버값 "리디"→"리디북스"** 변경 | Search | 🟡 백엔드 확인 | 의도됨(사용자 확정·#185) | 서버 enum이 "리디북스"를 수용하는지 재확인 |
| 6 | **리뷰 `keywordIds` 화면 미배선** — 현재 항상 `[]` | NovelReview | 🟢 배선 대기 | 계약서 §7 | 키워드 선택 화면 연결(후속) |

> **값 parity 확정(V2 코드 확인 완료, 이슈 없음)**: gender `"M"`/`"F"`(로컬 저장은 `"MALE"`/`"FEMALE"`로 별도),
> 읽기상태 `WATCHING`/`WATCHED`/`QUIT`, 리뷰 상태·날짜(`yyyy-MM-dd`), 소소피드 옵션 `ALL`/`RECOMMENDED`(명시 rawValue),
> 장르 토큰(`romance`/`romanceFantasy`/…), 서재 정렬(`created_desc` 등, `.uppercased()` 불요 — 원래 소문자 토큰).

---

## 1. 전수 감사 결과 (C2의 핵심)

### 1.1 "조건부 필터를 non-optional로 둬 항상 전송" 부류 — **`isCompleted` 유일**

모든 `*Query.swift`(15종)를 감사했다. **미선택을 표현해야 하는데 non-optional로 둔 필드는
`DetailSearchQuery.isCompleted: Bool` 하나뿐**이다. 나머지는 전부 안전하다:

- `UserLibraryV2Query`(서재) — 전 필터 `Optional`. `isCompleted`도 `Bool?`이고 매퍼가
  `publicationStatus.map { $0 == .completed }`라 미선택이면 nil→생략. **Search가 고쳐야 할 올바른 모델**이다.
- `GetUserFeedsQuery`(내 피드) — `isVisible`/`isUnVisible`/`genreNames`/`sortCriteria` 전부 `Optional`.
- 그 외(`NormalSearchQuery`·`NotificationQuery`·`GetNovelFeedsQuery`·`GetSosoFeedsQuery`·`BlockUserQuery`·
  `ValidateNicknameQuery`·`CollectionsQuery`·`CollectionDetailQuery`·`SearchKeywordQuery`·`AppMinimumVersionQuery`)
  — 필수 파라미터(`query`/`page`/`size`/`cursor`/`os`)거나 항상 값이 있는 열거형(`feedsOption`=ALL/RECOMMENDED)뿐.

**→ isCompleted 회귀는 이 부류의 예외적 단일 사례이지, 만연한 패턴이 아니다.** (안심 근거이자, 이 하나만 고치면 이 축은 닫힌다.)

### 1.2 "`rawValue` 그대로 전송해 서버 토큰과 대소문자가 어긋남" 부류 — **내 피드 정렬**

Data에서 열거형 `rawValue`를 쿼리에 직접 싣는 지점을 전수 확인했다:

| 지점 | 방식 | V1 서버값 | V2 서버값 | 판정 |
|---|---|---|---|---|
| 읽기상태(서재) `NovelMapper:270` | `value.rawValue.uppercased()` | `WATCHING`… | `WATCHING`… | ✅ 방어적 대문자화 |
| 컬렉션 정렬 `CollectionDetailQuery:19` | `sortType.rawValue.uppercased()` | (대문자) | (대문자) | ✅ 방어적 대문자화 |
| 소소피드 옵션 `DefaultFeedRepository:118` | `option.rawValue` | `ALL`/`RECOMMENDED` | `ALL`/`RECOMMENDED`(명시 rawValue) | ✅ parity |
| **내 피드 정렬 `DefaultFeedRepository:186`** | **`option.sortType.rawValue`** | **`RECENT`/`OLD`** (V1 `SortType.queryText`) | **`recent`/`old`** (`BaseDomain.SortType` case명) | 🟠 **대소문자 불일치** |

`BaseDomain.SortType`은 `case recent`/`case old`에 명시 rawValue가 없어 `"recent"`/`"old"`(소문자)로 직렬화된다.
V1은 같은 `/users/{id}/feeds`에 `sortCriteria=RECENT`/`OLD`(대문자, `UserInfoRepository:121` →
`SortType.queryText`)를 보냈다. **타 모듈(읽기상태·컬렉션 정렬)이 전부 `.uppercased()`로 방어하는데 내 피드만
빠졌다** — 서버가 대소문자 민감이면 V2 내 피드 정렬이 조용히 서버 기본값으로 떨어진다(=정렬 무효).

> **확인 방법**: `/users/{userId}/feeds?sortCriteria=recent` vs `=RECENT`의 정렬 결과가 같은지 실서버 대조
> (`isCompleted` 실서버 검증과 동일 방식). 다르면 `option.sortType.rawValue.uppercased()`로 1줄 수정.

---

## 2. 모듈별 요약 (부록 A 종합 — 상세는 각 계약서)

대부분 ✅ Keep이고, ✅가 아닌 것만 추린다(전체 행은 각 모듈 `V1_BEHAVIOR_CONTRACT.md`의 `부록 A`).

| 모듈 | ✅가 아닌 매핑(요지) |
|---|---|
| **Feed** | `sortCriteria` 대소문자(위 §1.2, 🟠) · `isVisible`/`isUnVisible`/`genreNames` V1은 all일 때도 전송·V2는 생략(🔧 의도) · `etc` sentinel(미분류, 🔧 의도) |
| **Search** | `isCompleted` 항상 전송(🔴 §0-1) · 빈 배열 `?key=`(🟡 §0-4) · 플랫폼 "리디북스"(🟡 §0-5) · 최근검색어/인증정책 ✅ |
| **Library** | `isCompleted`=`publicationStatus.map{…}`(🔧, **올바른 Optional 모델**) · 그 외 필드 V1과 일치 |
| **NovelReview** | `keywordIds` 화면 미배선→`[]`(🟢 §0-6) · POST→PUT 폴백(🔧 의도) · 나머지 body 동일 |
| **Notification** | 라우팅 `novelId` 신규·`feedId·novelId 無`→`unknown`(V1은 -1 push 깨짐)(🔧 개선) · 엔드포인트/읽음 전송조건 ✅ |
| **Setting** | 탈퇴 body `refreshToken` 제거(🟡 §0-3) · 알림설정 저장 낙관화(🔧 개선) · 로그아웃/공개설정/성별나이/차단해제 ✅ |
| **Onboarding** | 닉네임 실패사유 세분 로컬 흡수(🔧) · 프로필등록/약관 body 동일 ✅ |
| **UserPage** | 피드 신고·좋아요 신규(V1 no-op)(🔧 개선) · 프로필/서재통계/취향/차단 ✅ · `getUserFeed`의 `filterOption`/`sortType`은 V1 죽은 파라미터 |
| **Home** | 쿼리 없는 GET 4종 ✅ · 관심글 엔드포인트는 홈 미호출(🗑 §1.3) |
| **Keyword** | 소스가 서버 GET→로컬 DB 캐시(🔧, §3) · 응답 스키마 로컬 흡수 |
| **NovelDetail** | 엔드포인트 전부 ✅ · 피드 페이지 크기 20→? 확정 별도(경미) |

---

## 3. 판정 항목 상세

### 3-1 🔴 검색 `isCompleted` (확정 회귀)
- **증상**: 연재상태 미선택 시 `isCompleted=false`가 항상 전송 → 서버가 "연재중만"으로 해석해 **완결작 90% 누락**.
- **실서버 검증(2026-08-28)**: `/novels/filtered`에서 `false`=9,319 · `true`=85,708 · 생략=95,027(=9,319+85,708).
- **위치**: `DetailSearchQuery.isCompleted: Bool`(non-optional) · `SearchMapper.detailSearchQuery`가 `filter.publicationStatus == .completed`로 항상 Bool 생성.
- **고침 기준**: `Bool?`로 바꾸고 매퍼를 `filter.publicationStatus.map { $0 == .completed }`로(= Library와 동일). nil→`QueryItemConvertible`이 자동 생략. → **TODO §9**, `SearchData/CLAUDE.md`에 기록됨.

### 3-2 🟠 내 피드 정렬 대소문자 (회귀 유력, 본 C2 신규 발견)
- **위치**: `DefaultFeedRepository.swift:186` `sortCriteria: option.sortType.rawValue`.
- **불일치**: V1 `RECENT`/`OLD`(대문자) ↔ V2 `recent`/`old`(소문자). 타 모듈은 전부 `.uppercased()`.
- **판정 기준**: 서버 대소문자 민감이면 회귀(정렬 무효) → `.uppercased()` 1줄. 민감하지 않으면 무해(그래도 일관성 위해 대문자화 권장).

### 3-3 🟡 탈퇴 body `refreshToken` 제거 (백엔드 확인)
- **위치**: `WithdrawRequest = { reason }`(V2) vs V1 `{ reason, refreshToken }`. 경로 동일 `/auth/withdraw`, 인증은 access 헤더.
- **판정 기준**: 백엔드 V2 스펙이 body의 refreshToken을 요구하지 않으면 ✅(정리). 요구하면 누락. → 사용자만 풀 수 있는 백엔드 확인.

### 3-4 🟡 검색 필터 빈 배열 `?key=` 빈값 (검증 권장)
- **위치**: `DetailSearchQuery`의 `genres`/`platformNames`/`keywordIds`가 non-optional 배열 → 미선택 시 `?genres=`(빈 값).
- **대조**: `UserLibraryV2Query`는 같은 함정을 알고 전 배열을 `Optional`로 둬 생략한다(주석 명시). Search만 다른 모델.
- **판정 기준**: 상세검색이 실제로 동작하므로 서버가 빈 값을 "무필터"로 관용할 가능성이 크나, Library와 규칙이 갈린다 — 서버 관용을 확인하거나 `Optional`로 통일(isCompleted 수정과 함께 하면 자연스럽다).

### 3-5 🟡 플랫폼 "리디"→"리디북스" (백엔드 확인)
- V1 `NovelPlatform.title`의 `.ridi`="리디" ↔ V2 `mapNovelPlatformString`의 `.ridibooks`="리디북스". 의도된 변경(사용자 확정·#185, `SearchData/CLAUDE.md` 문서화)이나 **서버 enum이 "리디북스"를 실제로 수용하는지**의 실측 근거는 문서에 없다 → 재확인 권장.

### 3-6 🟢 리뷰 `keywordIds` 미배선 (배선 대기)
- 키워드 선택 화면이 아직 연결 안 돼 `draft.keywords`가 항상 비어 `keywordIds=[]`로 나간다. 매핑 자체는 옳고(선택되면 `id.value` 배열), **화면 배선이 후속**이다. → 계약서 §7.

---

## 부록 — C2 작업 방법(재현용)

1. 각 모듈 `V1_BEHAVIOR_CONTRACT.md`의 `## 부록 A` 인벤토리(11개 모듈, Collection은 V1 없음 제외).
2. `Core/Networking/QueryParameters.swift`의 직렬화 규칙 확정 → 위험 두 축 도출.
3. `Projects/Data/**/*Query.swift`(15종) 전수 감사 → non-optional 조건부 필터 색출(`isCompleted` 유일).
4. Data에서 `.rawValue` 직접 전송 지점 grep → 대소문자 대조(`../WSS-iOS`의 V1 값과 비교, 내 피드 정렬 적발).
5. 값 parity(gender·상태·정렬·장르·플랫폼)를 V2 매퍼로 확인, V1과 대조.
