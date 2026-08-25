# TODO — 알고도 미룬 것들

작업 중 **발견했지만 그 PR 범위를 벗어나 미룬 것**을 모아둔다. 잊히면 다시 발견하는 데 드는 비용이 커서,
"왜 지금 안 했는지"와 "어디를 고쳐야 하는지"를 함께 남긴다.

## 어디에 적나 (이슈·코드 주석과의 구분)

| 성격 | 어디에 |
|---|---|
| 그 자체로 하나의 작업 단위(새 화면·기능·모듈) | **GitHub 이슈** — 담당자·브랜치가 붙는다 |
| 다른 작업 중 발견했으나 범위를 벗어나 미룬 것. 착수 시점 미정 | **이 문서** — 착수할 때 이슈로 승격한다 |
| 그 파일만 보면 이해되는 국소적인 것 | **코드의 `// TODO:`** — 여기 옮기지 않는다 |

- **"언젠가 서버가 주면", "나중에 필요해지면" 같은 조건부 희망사항은 적지 않는다.** 지금 결론이 난 것은
  그 결론을 해당 `CLAUDE.md`에 못 박으면 되고, 여기 남기면 미완성처럼 보인다.
- 항목을 끝내면 **줄을 지운다**(완료 목록을 쌓지 않는다 — 히스토리는 git이 갖고 있다).
- 이슈로 승격했으면 항목에 이슈 번호를 달고, 그 이슈가 닫힐 때 지운다.

---

## 열린 항목

### 1. 로그인 세션이 끝나도 로컬 프로필 캐시가 남는다

- **무엇**: `DefaultAuthRepository`의 `logout()`·`withdraw()`가 `tokenStore.clearTokens()`만 호출하고
  `UserDefaults`(`UserDefaultsStorage`)에 쌓인 **사용자 값 5개를 그대로 남긴다** —
  `userID`·`nickname`·`characterID`·`gender`·`birthYear`(`StorageKey.swift`). Auth 쪽엔 `appStorage` 의존 자체가 없다.
- **결과**: 계정을 갈아타면 **이전 사용자의 값이 다음 사용자 화면에 비칠 수 있다.** 로그인 직후 프로필 조회가
  캐시를 덮기 전에 화면이 먼저 뜨면 드러난다.
- **어떻게 드러났나**: #179(홈)에서 이 캐시를 **읽는 첫 소비자**가 생겼다 — 추천글 섹션 제목이
  "{닉네임}님을 위한 추천글"이라 이전 사용자의 닉네임이 그대로 노출된다. 캐시를 쓰는 쪽은 이전부터
  `ProfileData`(프로필 조회·수정 시 저장)였으나 읽는 화면이 없어 가려져 있었다.
- **어디를 고치나**: `Projects/Data/AuthData/Sources/Repository/DefaultAuthRepository.swift`의 두 경로 +
  `Projects/Data/BaseData/Sources/LocalStorage/UserDefaultsStorage.swift`.
  ⚠️ **일괄 삭제 API가 없다** — 현재 프로토콜은 `get`/`set`뿐이라 `remove`(또는 세션 스코프 초기화)를 먼저 얹어야 한다.
- **왜 지금 안 했나**: #179는 홈 화면 범위였다. Auth·Profile까지 넓히면 그쪽 리뷰·테스트를 다시 돌려야 해서 분리했다.
- **놓치기 쉬운 것**: 닉네임만 지우면 반쪽이다. 위 5개가 **모두 사용자 개인 값**이라 함께 다뤄야 하고,
  로그아웃뿐 아니라 **탈퇴**에도 같은 처리가 필요하다.

### 2. 강제 업데이트 알럿이 아직 아무 데서도 호출되지 않는다

- **무엇**: 서버가 주는 최소 버전과 현재 앱 버전을 비교해 **업데이트 필요 알럿**을 띄우는 흐름 —
  Domain(`SettingDomain/Sources/AppUpdate/`: `AppVersion`·`AppUpdatePolicy.requiresForceUpdate(current:)`·
  `AppUpdateRepository`·`CheckForceUpdateRequirementUseCase`)과 Data(`DefaultAppUpdateRepository` +
  `SettingDataFactory.makeAppUpdateRepository(client:logger:)`)는 **테스트까지 완비돼 있는데 부르는 쪽이 없다.**
- **결과**: 서버가 최소 버전을 올려도 구버전 앱이 그대로 굴러간다. 비교 로직은 이미 있으니 남은 건 배선뿐이다.
- **어디를 고치나**: `Projects/App/` — 조립(`NetworkingClient` → Repository → UseCase) + 앱 진입 게이트.
  ⚠️ **`AppVersionProviding` 실구현체가 없다**(`Testing/Mock/MockAppVersionProvider`만 존재) —
  `Bundle`의 `CFBundleShortVersionString` → `AppVersion` 파싱을 새로 써야 한다. 프로토콜만 보고
  "구현체가 어딘가 있겠지" 하기 쉬운 자리다.
- **왜 지금 안 했나**: #179는 홈 화면 범위였다. 그리고 App이 아직 스켈레톤(`ContentView`가 "Hello, World!")이라
  **이 작업이 App의 첫 실전 조립**이 된다 — 탭바·라우팅 구조와 함께 정해야 게이트를 어디에 걸지가 확정된다.
- **놓치기 쉬운 것**:
  - ⚠️ **HomeFeature에 넣지 말 것.** 홈은 탭 복귀마다 `.load`가 도는 화면이라 탭을 옮길 때마다 재체크되고,
    딥링크·알림·온보딩으로 다른 화면에 바로 진입하는 경로는 아예 안 걸린다. 앱 전역 게이트라 App 몫이다.
    (덤으로 홈이 `SettingDomain` 의존을 새로 물게 된다.)
  - **정책 조회가 실패하면 통과시켜야 한다** — 서버 장애로 앱을 통째로 못 쓰게 만들면 안 된다.
    **이 분기는 디자인 시안에 없으니** 구현 시 명시적으로 정할 것.
  - `WSSAlert`는 **버튼 탭이 표시 상태를 자동으로 닫지 않는다**(모든 `buttonActions`가 스스로 되돌려야 함).
    강제 업데이트는 "닫기 불가 + 앱스토어 이동"이라 이 계약과 정면으로 맞물린다 — 기존 컴포넌트로
    커버되는지 먼저 확인할 것.
- **디자인**: [Figma — 업데이트 알럿](https://www.figma.com/design/QLYZA00K5EIozTroOTDYAU/%EC%9B%B9%EC%86%8C%EC%86%8C-%EB%94%94%EC%9E%90%EC%9D%B8?node-id=20238-24073&m=dev)

### 3. `Info.plist`의 `KAKAO_API_KEY`(단수)가 정의되지 않은 채 남아있다

- **무엇**: `Projects/App/Support/Info.plist`에 `KAKAO_API_KEY`(단수형) 키가 `$(KAKAO_API_KEY)`로 참조돼 있는데,
  `Config/*.xcconfig` 어디에도 이 이름으로 정의된 값이 없다. #176에서 실제로 쓰는 건 별도로 추가한
  `KAKAO_APP_KEY`(복수형, `Config_Shared.xcconfig`에 정의됨)다.
- **결과**: 지금은 무해(빌드 시 빈 문자열로 치환될 뿐 크래시 없음)하지만, 이름이 비슷해 헷갈리기 쉽다.
- **어디를 고치나**: `Projects/App/Support/Info.plist`에서 `KAKAO_API_KEY` 항목 제거(또는 실제로 필요한
  용도가 있었는지 확인 후 `KAKAO_APP_KEY`로 통일).
- **왜 지금 안 했나**: #176(온보딩 인트로) 범위 밖의 기존 잔재라 diff에 포함시키지 않았다(리뷰 중 발견, 2026-08).

### 4. 최종 이관(cutover) 시 운영 앱의 Bundle ID·서명 팀으로 교체해야 한다

- **무엇**: WSS-iOS-V2는 지금 운영 중인 기존 앱을 **나중에 완전히 대체**할 새 프로젝트다(사용자 확정).
  백엔드는 이미 같은 서버/DB를 공유하지만, 클라이언트 쪽 Bundle ID·서명 팀은 아직 운영 앱과 **다르다**
  (현재 `kr.websoso.app.WSS-iOS`, `Plugins/EnvironmentPlugin/ProjectDescriptionHelpers/ProjectEnvironment.swift`
  하드코딩). Apple 로그인 유저 식별자(`sub`)는 **(Apple Developer 팀 ID + Bundle ID)** 조합에 고정되고,
  Kakao 로그인은 App Key(이미 운영 키 `Config/Config_Shared.xcconfig`의 `KAKAO_APP_KEY` 재사용 중)는
  같아도 SDK가 런타임에 **호출 앱의 Bundle ID·서명 키해시가 Kakao 콘솔의 iOS 플랫폼 등록값과 일치하는지**
  검사한다. 이 값들이 운영 앱과 다른 채로 배포하면 기존 유저가 로그인해도 **다른 계정으로 인식**된다.
- **결과**: 백엔드가 공유돼 있어 별도 계정 마이그레이션 로직은 필요 없지만, 아래 항목이 정확히 안 맞으면
  기존 유저의 Apple/Kakao 로그인이 "신규 가입"으로 잘못 처리된다.
- **어디를 고치나(컷오버 시점에)**:
  1. `Plugins/EnvironmentPlugin/ProjectDescriptionHelpers/ProjectEnvironment.swift`의
     `organizationName`/`targetName` → 운영 앱의 실제 Bundle ID로 교체 후 `tuist generate`.
  2. **`DEVELOPMENT_TEAM`을 리포 어디에도 설정한 적이 없다**(확인됨, xcconfig·`Project.swift`·pbxproj
     전부 없음) — 운영 앱을 만든 것과 **같은 Apple Developer 팀 계정**으로 서명하도록 추가해야 한다.
  3. Apple Sign-in capability는 운영 Bundle ID의 App ID에 이미 켜져 있을 것 — 신규 등록 불필요, 확인만.
  4. Kakao Developers 콘솔의 해당 앱(App Key 그대로) → 플랫폼 → iOS에 운영 Bundle ID + **새로 서명한
     배포 인증서의 키해시**가 등록돼 있는지 확인/추가.
  5. App Store Connect에 **운영 앱과 정확히 같은 앱 레코드**로 새 빌드 업로드(별도 신규 리스팅 금지 —
     기존 유저가 일반 업데이트로 받아야 리뷰·랭킹·설치기반이 유지됨, 사용자 확정).
  6. 컷오버 직전, 실제 배포 서명으로 실기기에서 Apple/Kakao 로그인이 "기존 계정 인식"으로 뜨는지
     서버 응답으로 리허설 검증.
- **왜 지금 안 했나**: 사용자 결정 — 지금은 개발용 설정으로 계속 진행하고, 실제 스위치(운영 앱을
  이 코드베이스로 교체하는 시점)에 한 번에 전환하기로 함(2026-08-12).
- **놓치기 쉬운 것**: Kakao 키해시는 서명 인증서 기준이라 같은 팀 인증서를 쓰면 대체로 그대로겠지만
  Xcode 프로젝트가 통째로 바뀌는 이관이라 **반드시 실측 검증**할 것 — 추측으로 넘어가지 말 것. Push
  (APNs)·Universal Link(`apple-app-site-association`) 등 Bundle ID에 종속된 다른 설정이 운영 앱에
  더 있다면 같은 시점에 함께 점검 대상.
### 5. 401과 "재발급까지 해봤지만 실패"가 Data 레이어에서 구분되지 않는다

- **무엇**: `NetworkingError+RepositoryError.swift`가 `responseFailure(401)`과 `requiresReauthentication`을
  **둘 다 `.authenticationRequired`로** 보낸다. 상위에서는 "그냥 401이 왔다"와 "재발급을 시도했는데 세션이 죽었다"를
  구분할 수 없다.
- **결과**: 재시도 상한(요청당 재발급 2회)을 다 쓰고 나온 401이 진짜 세션 만료와 똑같이 취급되어 **로그인 화면으로 튕긴다.**
  `.authenticationRequired`를 받아 로그인 라우팅을 거는 ViewModel이 여럿이다
  (`HomeViewModel`·`LibraryViewModel`·`UserLibraryViewModel`·`NovelDetailViewModel`·`NovelReviewViewModel` — 착수 시
  `rg "requiresAuthentication = true"`로 다시 세어볼 것. 화면이 늘면 자동으로 늘어난다).
- **어디를 고치나**: `Projects/Data/BaseData/Sources/Networking/NetworkingError+RepositoryError.swift` +
  `RepositoryError`에 케이스를 나눌지 결정 → 소비하는 ViewModel 전부의 분기.
- **왜 지금 안 했나**: #184는 중복 재발급 자체를 없애는 범위였다. 세 겹 방어(coalescing·토큰 세대 비교·세션 종료 판정 분리)로
  **이 경로에 도달하는 빈도 자체가 매우 낮아졌고**, 에러 타입을 쪼개면 Data·Feature 여러 모듈의 테스트를 다시 돌려야 한다.
- **놓치기 쉬운 것**: 값을 쪼개는 게 목적이 아니라 **"어디까지를 로그아웃으로 볼 것인가"** 라는 UX 결정이 먼저다.
  결론이 나면 그 결론을 `Projects/Core/Networking/CLAUDE.md`와 `Projects/Data/BaseData/CLAUDE.md`에 못 박을 것.

### 6. 병렬 로드에서 인증 만료가 다른 에러에 가려질 수 있다

- **무엇**: `HomeViewModel.load()`가 홈 데이터와 알림 상태를 `async let`으로 동시에 부르고 **앞의 것을 먼저 `await`** 한다.
  홈 데이터가 `.serverUnavailable`, 알림이 `.authenticationRequired`를 동시에 던지면 앞의 에러만 잡혀
  전면 실패 뷰가 뜨고 **로그인 라우팅은 걸리지 않는다**(Feature 레이어의 "인증 만료는 어느 catch든 로그인 라우팅" 계약 위반).
- **결과**: 세션이 죽었는데 "네트워크 오류" 화면에서 재시도만 반복하게 된다.
- **어디를 고치나**: `Projects/Feature/HomeFeature/Sources/Home/HomeViewModel.swift`의 병렬 로드 블록.
  같은 모양이 다른 화면에 복사되면 함께 본다.
- **왜 지금 안 했나**: **기존 순차 코드도 우선순위는 같았다**(홈 데이터가 먼저 실패하면 알림은 아예 호출되지 않았다) —
  #184의 병렬화가 만든 회귀가 아니다. 세션이 죽으면 홈 데이터도 401을 받으므로 실제 발생 조건이 드물고,
  고치려면 두 결과를 `Result`로 수확해야 하는데 **이 레포는 `Result` 사용을 지양한다.**
- **놓치기 쉬운 것**: `Result` 없이 풀려면 인증 만료를 먼저 판정할 다른 수단(에러 우선순위 비교, 또는 UseCase 쪽에서 합치기)이
  필요하다. `LoadHomeDataUseCase` 내부의 3개 병렬 호출도 같은 성질을 가지므로 함께 결정할 것.

### 7. 재시도로 복구되는 실패와 아닌 실패가 같은 화면으로 보인다

- **무엇**: `NetworkErrorView`의 문구가 **"네트워크 연결에 실패했어요 / 연결 상태를 확인한 후 다시 시도해 보세요"로 고정**이다.
  서버 5xx(`.serverUnavailable`)로 실패해도 같은 화면이 뜬다.
- **결과**: 원인을 **틀리게** 알려준다. 서버가 죽은 건데 사용자는 자기 와이파이를 껐다 켜며 헤맨다.
  반대로 진짜 연결 문제일 때와 구분이 안 돼 "기다리면 되는지 / 내가 뭘 해야 하는지"를 판단할 근거가 없다.
- **어디를 고치나**: `Projects/UI/WSSComponent/Sources/Network/NetworkErrorView.swift` +
  각 ViewModel이 `RepositoryError`의 원인을 화면까지 넘기는 배관.
  ⚠️ **공용 컴포넌트다** — 홈뿐 아니라 서재·작품 상세·리뷰 등 실패 화면이 전부 이걸 쓴다. API를 바꾸면 전 화면을 훑어야 한다.
- **왜 지금 안 했나**: #184는 재발급 중복 제거 범위였고, 무엇보다 **"서버 오류" 상태의 디자인 시안이 없다**(2026-08-22 확인).
  문구·일러스트를 임의로 지어내면 디자인과 어긋난다 → 시안이 나온 뒤 착수한다.
- **놓치기 쉬운 것**:
  - **값은 이미 있다** — `RepositoryError`가 `networkUnavailable`과 `serverUnavailable`로 나뉘어 있는데 화면이 안 쓰고 있을 뿐이다.
    새 에러 타입을 만들 일이 아니다.
  - ⚠️ **`/reissue`가 5xx일 때 지금은 로그인 화면으로 보낸다**(재인증 갈래 — `Projects/Core/Networking/CLAUDE.md`의 표).
    서버 장애면 다시 로그인해도 실패하므로 "잠시 후 다시" 쪽이 옳을 수 있는데, **뷰가 갈리지 않은 상태에서 갈래만 바꾸면**
    "네트워크 연결에 실패했어요"라는 틀린 문구를 보게 된다. **뷰 분기가 먼저이고, 그때 이 갈래도 함께 결정한다.**

### 8. 피드 공개범위(`VisibilityType`) 변환이 Repository와 Service로 이중으로 쪼개져 있다

- **무엇**: `MyFeedOption.visibilityType`(Domain enum, 3-값: `privateOnly`/`publicOnly`/`all`)이 서버 파라미터로 가기까지
  **두 계층에서 두 번** 변환된다.
  1. `DefaultFeedRepository.fetchMyFeeds`가 `FeedMapper.visibilityString(from:)`으로 enum → 문자열(`"PUBLIC"`/`"PRIVATE"`/`"ALL"`)
  2. `DefaultFeedService.getMyFeeds`가 그 문자열을 다시 `isVisible: Bool?` / `isUnVisible: Bool?`로
     (`visibilityType == "PUBLIC" ? true : nil`)
  중간의 문자열은 Repository→Service 전달용 임시 표현일 뿐이고, 최종 쿼리 파라미터 매핑이 **Service로 새어나가 있다.**
- **결과(냄새·잠재 버그)**:
  - 계층 책임 위반 — 요청 파라미터 매핑은 Repository/`FeedMapper`에 모여야 하는데 유독 이 파생만 Service에 있다(다른 메서드는 통과 계층).
  - `"ALL"`을 Service가 **명시적으로 다루지 않는다**(둘 다 nil로 떨어져 우연히 맞음). enum→문자열로 낮춰서
    **`switch` 누락 검사를 컴파일러가 못 한다** — 서버 스펙이 바뀌거나 오타가 나면 조용히 "전체"로 처리된다.
  - **테스트 사각지대** — Service 단위 테스트가 없고 Repository 테스트는 Service를 mock하니, 이 `문자열→Bool?` 변환은
    어느 테스트도 지나가지 않는다.
- **어디를 고치나**: 매핑을 한 곳으로 모은다 — Repository(또는 `FeedMapper`)가 `VisibilityType` enum → 완성된 쿼리 값까지
  한 번에 만들고, `DefaultFeedService.getMyFeeds`는 **판단 없이 통과**시킨다. `Projects/Data/FeedData/Sources/Service/DefaultFeedService.swift`
  + `.../Repository/DefaultFeedRepository.swift` + `.../Mapper/FeedMapper.swift`.
  ⚠️ **다른 Feed Service 메서드도 Query를 Service 안에서 조립**한다(`getNovelFeeds` 등) → "Query 조립은 Repository, Service는 통과"를
  **컨벤션으로 먼저 정하고** 함께 옮겨야 한다. 한 메서드만 바꾸면 두 벌로 갈린다.
- **왜 지금 안 했나**: 테스트 체계 정비(지도 이슈) 논의 중 발견한 별건이다. 지금 동작은 정상이라 급하지 않고,
  컨벤션 결정이 선행돼야 해서 분리한다.
- **놓치기 쉬운 것**: 이건 **자동 검사의 사각지대 표본**이다 — "매핑은 어느 계층 소관인가"는 의미 판단이라 린터로 못 잡고,
  지금 리뷰어 눈에도 안 띄어 통과했다. 근본 예방책은 **타입을 좁혀 leak을 문법적으로 불가능하게** 만드는 것
  (Service가 `String` 대신 완성된 Query를 받으면 변환할 거리가 없어진다). 정적 검사로는 "Service 파일에 분기(`if`/`switch`/`?:`) 금지"가
  싼 그물이 된다(지도 이슈 A2 후보).

### 9. PR CI가 매번 전체 모듈을 돌린다 — 변경 영향권만 도는 선택적 테스트(Tuist)로 최적화

- **무엇**: A1(#208)에서 `.github/workflows/test.yml`이 PR마다 `.tests`를 선언한 정식 모듈 30개 **전부**를
  `xcodebuild test`로 병렬 실행한다. 이번 변경과 무관한 모듈도 매번 돈다.
- **결과**: 문서·한 모듈만 바꾼 PR도 macOS 러너 30대를 쓴다 — 첫 실행 20~40분+, 비용·동시성 부담.
  Tuist/DerivedData 캐시로 완화되지만 근본적으로 낭비다.
- **어디를 고치나**: `xcodebuild test` 직접 호출 → **Tuist 선택적 테스트(`tuist test`)** 로 전환. Tuist가 각 모듈의
  콘텐츠 해시로 "안 바뀐 건 건너뛰고, 바뀐 것 + 그 **영향권**(직·간접으로 의존하는 하위 모듈)만" 돌린다.
  워크플로우의 discover/matrix 구조와 gate 로직을 함께 손봐야 한다.
  - ⚠️ **의존성 전파가 핵심**: 순진한 "git diff 모듈만" 방식은 공용 모듈(`BaseDomain`·`Networking` 등)을 바꿨을 때
    그걸 쓰는 하위 모듈을 안 돌려 **거짓 초록불**을 낸다. Tuist는 역의존까지 계산해 이 함정을 피한다 —
    그래서 diff 필터가 아니라 **Tuist 그래프 기반**이어야 한다.
  - ⚠️ **gate 재설계**: 지금 `All Tests Passed`는 "matrix 전부 success"를 본다. 선택 실행이면 PR마다 도는 모듈 수가
    달라지고, **문서만 고친 PR은 도는 모듈이 0개**가 된다 — 그걸 "통과(돌 게 없음)"로 볼지 규칙을 명시해야
    required check가 안 깨진다.
  - Tuist 바이너리 캐시(binary cache)를 붙이면 빌드 자체도 크게 빨라진다 — 선택적 테스트와 함께 검토.
- **왜 지금 안 했나**: A1의 목적은 "자동 트리거 + 전수 게이트를 먼저 세우는 것"이었다. 게이트 안정화 전에 선택 실행까지
  얹으면 한 PR이 두 가지를 동시에 바꿔 문제 원인 규명이 어렵다. 첫 실행 비용을 실측한 뒤 최적화를 결정하기로 함
  (2026-08-25, 지도 이슈 #205 축 A 후속).
- **놓치기 쉬운 것**: 선택적 테스트의 목적은 "빠르다"가 아니라 **"정확히 영향권만"** 이다. 영향권 계산이 틀리면
  빠른 대신 거짓 초록을 낸다 — 속도보다 의존성 전파 정확도가 우선이다.
