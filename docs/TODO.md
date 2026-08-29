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

## 열린 항목: 기능·제품

기능 작업(화면·기능 PR)에서 발견했으나 그 범위를 벗어나 미룬 제품/기능 결함·배선.

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
- **왜 지금 안 했나**: #179는 홈 화면 범위였다. #196에서 App의 첫 실전 조립(온보딩 플로우 배선)은
  끝났지만, 메인 탭바·라우팅 구조가 아직 없어(`ContentView`의 `.main`은 여전히 placeholder) 강제
  업데이트 게이트를 정확히 어느 지점에 걸지는 그 구조가 잡혀야 확정된다.
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

### 8. 컬렉션 "공유하기" ✅구현됨(#228, 카카오 공유 카드) / 남은 것: Universal Link(카카오 외 채널 공유)

- **무엇(해소)**: "공유하기"가 **카카오 공유 카드(`KakaoSDKShare`/`KakaoSDKTemplate`, "앱에서 보기" →
  `kakao{APP_KEY}://kakaolink?collectionId={id}`)** + 앱 내 라우팅(지금 선택된 탭 위에 push)으로 구현됐다
  (2026-08-29, 사용자 확정). 카카오톡이 있으면 카카오톡 앱, 없으면 카카오 웹 공유(Safari, SDK 권장 폴백).
  처음엔 iOS 기본 공유 시트 + `websoso://collections/{id}`만으로 갔다가, **카카오톡이 커스텀 스킴을 링크로
  인식하지 않아 수신자가 진입 못 하는 것**이 실기기에서 드러나 카카오 SDK를 다시 들였고, 그 시트도 걷어냈다
  (폐기 이력은 `CollectionFeature/CLAUDE.md`). 앱 미설치 수신자는 카카오가 App Store로 보낸다(콘솔 iOS
  플랫폼 등록 전제). 딥링크로 열린 "내" 컬렉션의 수정 트리는 4탭 전부 배선됐다(`CollectionEditAssembly`).
  자세한 배선은 `App/CLAUDE.md` 딥링크 항목, 링크 형식은 `BaseDomain.DeepLink`, 카드 구성은
  `CollectionFeature/CLAUDE.md`.
- **남은 것**: 카카오 밖(문자·복사·다른 메신저)으로는 공유할 수 없다 — 커스텀 스킴(`websoso://`)은 메시지
  앱에서 링크로 인식조차 안 돼 시스템 공유 시트에 실어봐야 무의미해서 뺐다. 한 링크로 "설치됨→앱,
  미설치→스토어/웹"을 자동 분기하려면 웹 랜딩 + Universal Link(`https://…`, AASA 호스팅 + Associated
  Domains entitlement)가 필요하고 이건 백엔드/웹 몫이라 `docs/PENDING_DECISIONS.md` 후보. 그게 생기면
  ① 시스템 공유 시트를 그 링크로 되살리고(폐기 이력의 함정 참고) ② 카카오 카드의 `Link.webUrl`/
  `mobileWebUrl`에도 같은 URL을 실을 것.
- **어디를 고치나**: `BaseDomain/DeepLink.swift`(https 형식 추가) + App `Info.plist`/entitlements +
  `CollectionDetailView.shareButton`(시트 재도입) + `CollectionKakaoShare.makeTemplate`(`webUrl`).

### 9. 콜드스타트 시 저장된 세션을 재사용하지 않는다(+ 로그아웃 상태에서 탭바가 순간 노출된다)

- **무엇**: `ContentView.route`의 기본값이 #197부터 `.main`이다(`@State private var route: Route = .main`,
  구 `.onboarding`). 세션 복원 로직 자체는 여전히 없다 — Keychain(`DefaultTokenStore`)에 유효한 토큰이
  남아있는지 확인해 분기하는 게 아니라, 무조건 메인 탭부터 그린다.
- **결과**: 로그인 성공 시 토큰이 저장되고 401 자동 갱신도 연결돼 있지만(#196), 그 지속성은 **같은
  프로세스 안에서만** 유효하다 — 강제 종료 후 재실행하면 토큰이 살아있어도 도로 로그인해야 한다.
  **게다가 #197부터는 로그아웃 상태(또는 토큰이 아예 없는 상태)로 앱을 켜도 몇 초간 `MainTabView`
  (탭바)가 먼저 보였다가 401로 온보딩에 튕겨 돌아간다** — `App/CLAUDE.md`의 "로그인 안 된 상태로
  `MainTabView`를 열면 몇 초 안에 온보딩으로 튕겨 돌아간다" 항목이 그 증상이다. `.onboarding` 기본값
  시절엔 이 노출 자체가 없었다는 점에서 체감상 회귀지만, **사용자 확정으로 지금은 그대로 둔다**(4탭이
  실제 화면으로 다 채워진 지금 상태를 UI 기준으로 유지하기로 함, 2026-08-28) — 세션 복원이 이 회귀의
  근본 해법이라 아래 작업과 함께 다룬다.
- **어디를 고치나**: `ContentView.init` 또는 `body` 진입 시점에서 기존 세션(access/refresh token)
  유효 여부를 확인해, 없으면 `route`를 `.onboarding`으로 시작하도록 분기를 추가한다(있으면 지금처럼
  `.main`). ⚠️ `tokenStore`는 현재 `AppDependencies.init()` 내부 지역 변수라 `dependencies.tokenStore`로
  바로 못 꺼낸다 — 착수 시 먼저 인스턴스 프로퍼티로 승격해야 한다.
- **왜 지금 안 했나**: #196 체크리스트 범위 밖(사용자 확인, 2026-08)이었고, #197(메인 탭이 실제로
  생기는 이슈)에서도 범위 밖으로 재확인됐다(2026-08-28) — 세션 복원 자체가 별도 작업 단위라 이 PR에
  묶지 않기로 함.

### 10. `UserPageFeatureDemoApp`의 마이페이지 편집·설정·서재 전환이 콘솔 로그로만 남아있다

- **무엇**: `Projects/Feature/UserPageFeature/Demo/UserPageFeatureDemoApp.swift`의 `makeMypageView`가
  `MypageFeatureFactory.makeView`의 현재 시그니처(`onCollectionTapped`/`onEditProfileTapped`/
  `onSettingTapped`/`onLibraryTapped` 콜백 4개 — #197에서 편집 진입도 App 콜백으로 통일)와 어긋나
  **컴파일이 안 되던 문제는 고쳤다**(`onCollectionTapped`와 동일하게 콘솔 로그만 남기는 no-op으로
  연결, 2026-08-28 rebase 중 실측 빌드 확인). 다만 실제 push/무시 여부는 아직 설계하지 않았다.
- **결과**: Demo에서 연필 아이콘·톱니바퀴·서재 블록을 눌러도 콘솔 로그만 찍히고 화면 전환은 없다
  (컴파일은 되니 CI엔 영향 없음).
- **어디를 고치나**: 위 파일의 `makeMypageView` — 프로필 편집·설정·서재 전환을 Demo 안에서 실제로
  흉내낼지(별도 push? 계속 무시?)부터 설계해야 한다.
- **왜 지금 안 했나**: 이번 rebase는 컴파일 회복이 목적이라 최소 수정(no-op)만 했다 — 실제 Demo 내비게이션
  설계는 별개 작업이라 분리했다.

### 11. 런치 부트스트랩(Splash)을 신설해 "앱 진입 시 할 일"을 한곳에 모은다 — 홈 프리페치 포함

- **허브 결정(사용자, 2026-08-28)**: V1 `Presentation/Splash`처럼 V2도 **`SplashFeature`(런치 부트스트랩)**를 두고, C1 판정에서
  "App 부트스트랩 몫"으로 밀어둔 작업을 전부 여기서 처리한다. **이슈 #225**로 승격(2026-08-28). 모을 작업:
  | 작업 | 출처 판정 |
  |---|---|
  | 유저 정보(`/users/me`) 조회 → 로컬 캐시(userId·nickname·gender·birth) 갱신 — **앱 진입마다** | Home 계약 6.2 (0절 9) |
  | 홈 프리페치(오늘의 발견·지금 뜨는 글) — 아래 본문 | Home 계약 1.5 (0절 3) |
  | 앱 최소 버전 조회 → 강제 업데이트 알럿(인프라 `SettingData`) | Home 계약 0절 5 · 위 기능 2번 |
  | 필수 약관 동의 게이팅(미동의 유저만 약관 시트) | Onboarding 계약 3.1 (0절 1) |
  | FCM 토큰 등록(`RegisterDeviceTokenUseCase`, 세션 있을 때) | Onboarding 계약 1.6 (0절 4) |
  | 로그인 세션 유무 라우팅(인트로 vs 홈) | 기존 App 골격 |
  | 키워드 로컬 캐시 동기화(`syncKeywords`) — 검색·카테고리가 로컬 캐시 기반이라 진입 시 갱신 | Keyword 계약 3 (0절 7) |

- **무엇**: V1은 `HomePrefetchService`로 오늘의 인기작·지금 뜨는 글을 **Splash 단계에서 미리 받아** 홈 진입 시
  소비해 첫 홈 표시 지연을 줄였다. V2엔 이 프리페치가 없다(홈 진입마다 새로 로드). 되살리기로 확정(사용자, 2026-08-27).
- **전제(선행 작업)**: **V2에 런치 부트스트랩 단계를 둔다**(사용자 확정). 현재 App이 스켈레톤이라 Splash/부트스트랩이
  없어(`grep Splash`=디자인시스템 에셋뿐) 프리페치를 얹을 자리가 없다. **프리페치 이득은 "런치→홈 표시 사이 dwell"에
  전적으로 달렸다** — 부트스트랩 없이 홈이 런치 즉시 뜨면 프리페치 착지 전에 홈 로드가 네트워크를 먼저 때려 이득이 0이다.
  즉 이 항목은 **부트스트랩 단계 신설에 종속**된다(강제 업데이트 게이트·토큰 검증 등과 같은 자리 → 위 기능 2번과 함께 볼 것).
- **어디를 고치나(할 때)**:
  1. **`HomePrefetchStore`(actor)** 신설 — `today`·`trending` 단발성(single-shot) 슬롯. `consume…()`은 값을 돌려주고
     슬롯을 비운다. (Data 또는 Core.)
  2. `DefaultRecommendationRepository`(현재 `struct`)가 이 actor **참조**를 보유 → `fetchTodayDiscoveries()`/
     `fetchTrendingFeeds()`가 store에 있으면 소비, 없으면 네트워크.
  3. 부트스트랩이 `PrefetchHomeDataUseCase`(또는 레포 fetch)를 fire-and-forget으로 호출해 store를 채운다.
  4. App DI가 `HomePrefetchStore` **단일 인스턴스**를 만들어 부트스트랩 트리거와 레포에 같이 주입.
- **왜 지금 안 했나**: C1(#222)은 V1 동작 계약 **추출·분류**만이 범위다. 구현은 부트스트랩 신설(App 첫 실전 조립)에
  종속돼 별건이다.
- **놓치기 쉬운 것**:
  - ⚠️ **V1의 `HomePrefetchService.shared` 싱글톤 방식 금지**(레포 철학). struct 레포엔 캐시 필드를 못 둔다(복사되어
    공유 불가) — actor store 참조 공유가 그 회피책.
  - ⚠️ **TTL 캐시 금지, single-shot이 정답** — 홈은 "탭 복귀마다 갱신" 계약이라 TTL이면 복귀 때 stale이 나온다.
    single-shot이면 프리페치가 슬롯 1회 채움 → 첫 홈 로드가 비움 → 이후 복귀 갱신은 전부 네트워크(V1과 정확히 일치).
  - **범위는 today·trending 2종만**(V1도 그랬음). taste(선호장르)는 느린 개인화라 제외, 알림 배지도 제외.
  - 전체 설계·근거의 정본: [`Projects/Feature/HomeFeature/V1_BEHAVIOR_CONTRACT.md`](../Projects/Feature/HomeFeature/V1_BEHAVIOR_CONTRACT.md) 1.5.

### 12. V1 parity 판정(#222 C1)에서 "되살리기/고치기로" 결정됐으나 미룬 것들

C1(#222) V1 동작 계약 추출 중 ❓Unknown으로 잡힌 항목을 사람이 판정한 결과, **되살리거나 고치기로 결정됐지만**
추출 PR 범위(문서화)를 벗어나 미룬 것. 상세·근거·인용은 각 모듈 `V1_BEHAVIOR_CONTRACT.md`. (판정 세션 2026-08-28)
서버 요청 파라미터 매핑의 V1↔V2 교차 종합(C2)은 [`docs/V1_PARAM_MAPPING_C2.md`](V1_PARAM_MAPPING_C2.md)가 정본.

- **앱 리뷰 요청(StoreKit) 재도입** — V1은 피드 작성/감상평 저장 성공 후 `AppReviewManager.requestReview()`로 앱
  평점 프롬프트를 띄웠다. V2 없음. 되살리되 **호출 타이밍은 재설계**(무분별 호출 금지). → `FeedFeature`·`NovelReviewFeature`.
- **피드 댓글/삭제 조용한 실패 표면화(회귀 확정)** — `FeedDetailViewModel`의 `createComment`·`editComment`·
  `deleteComment`·`deleteFeed`가 **빈 `catch {}` 4곳**으로 실패를 삼킨다(실측 확인). V1은 "네트워크 지연" 토스트 +
  전송버튼 재활성. 최소 에러 표면화 필요. → `FeedFeature`.
- **감상평 첫 진입 온보딩 힌트 재도입 (사용자 확정 2026-08-28)** — V1의 1회성 오버레이(딤 + 평가 상태바 미리보기 + 말풍선 힌트,
  닫으면 `UserDefaults`로 재노출 방지)를 되살린다. 디자인 시안은 구현 시 V1 구성을 재료로 요청. 근거: `NovelDetailFeature` 6.4·0절 4.
  → `NovelDetailFeature`.
- **피드 좋아요 햅틱 복원** — V1 좋아요에 light impact 햅틱. V2 목록 좋아요엔 없다(정렬 토글엔 있음). → `FeedFeature`.
- **피드 댓글 500자 제한 복원** — V1은 500자 하드컷. V2는 제한 없음(실측 확인). 무제한이면 서버가 긴 댓글 거부 시
  조용한 실패 위험. → `FeedFeature`.
- **내 피드 개수 표시 = 서버 `feedsCount` 사용 (사용자 확정 2026-08-28)** — V2는 로드된 배열 길이(`myFeeds.count`)라
  페이지네이션 전엔 최대 20까지만 세어 실제 총량과 다르다. 서버 응답 `UserFeedListResponse.feedsCount`(전체 개수)가
  실재하므로 매퍼/상태로 노출해 표시(V1 parity). → `FeedFeature`·`FeedData`.
- **피드 수정 "변경 감지" 게이트 복원 (사용자 확정 2026-08-28)** — V2 `canSubmit`이 "내용 비어있지 않음"만 봐 무변경
  재저장 가능(불필요 PUT·이미지 재업로드). V1처럼 내용·스포일러·공개·연결작품·이미지 중 하나라도 바뀌어야 완료 활성
  (`isInitialFeedChanged`). 겸사 **댓글 전송 버튼**도 무변경 재전송 가드 복원(초기값과 다를 때만 활성, 사소). → `FeedFeature`.
- **매력포인트 버튼 순서 V1로 정렬** — 결정: `worldview·material·필력(writingSkill)·character·relationship·vibe`
  (**필력 3번째**). 현재 V2는 필력이 맨 끝(둘 다 `allCases` 나열이라 우연히 다름). → `NovelReviewFeature`.
- **키워드 빈 화면 문의 버튼 목적지 되돌림(오배선)** — 빈 검색결과의 "문의" 버튼이 V2에서 `AppURL.inquiryAddNovel`
  (작품 등록 문의)로 잘못 연결됐다. V1은 **범용 문의**(`ExternalLinks.inquiry` = V2 `AppURL.errorReport`와 동일 URL).
  **범용 문의로 되돌릴 것**. (`KeywordFeature/CLAUDE.md`의 "전용 폼 없어 재사용" 설명은 정정 완료.) → `KeywordFeature`.
- **Amplitude 애널리틱스 횡단 재도입** — V1은 홈·작품상세·검색·키워드 등 곳곳에 이벤트를 심었다. V2 전무. 화면별
  계약이 아니라 **횡단 인프라**라 별도 이슈로 승격 대상. → 다수 모듈.
- ✅ **[완료 2026-08-28] 상세검색 연재상태 회귀 + 내 피드 정렬 대소문자** — 둘 다 C2에서 수정·빌드 검증
  완료(상세는 [`docs/V1_PARAM_MAPPING_C2.md`](V1_PARAM_MAPPING_C2.md) 3-1·3-2). `isCompleted`는 `Bool?` +
  매퍼 `.map`으로 미선택 시 쿼리 생략(완결작 90% 누락 회귀 해소), 내 피드 정렬은 `.uppercased()`로 통일(서버는
  대소문자 무관이나 표기 일관성). **잔여: `isCompleted` 매퍼 회귀 테스트**(SearchData `.tests` 타깃 미배선이라 후속).
- **검색창 자동 포커스 복원** — V1은 검색 화면 진입 시 키보드를 바로 띄웠다(becomeFirstResponder). V2는 자동
  포커스 없음(실측 — `@FocusState`만 있고 진입 시 true로 안 켬). 진입 시 `isFocused = true` 복원. → `SearchFeature`.
- **검색어 30자 제한 복원** — V1은 검색어 30자 초과 입력을 막았다(`shouldChangeCharactersIn`). V2는 제한 없음
  (실측). 서버 제약 가능성. → `SearchFeature`.
- **검색→작품상세·상세검색 네비게이션 배선(5경로)** — 소소픽·결과 셀→작품상세, 장르·키워드 더보기→상세검색,
  상세검색 진입경로 부재. 전부 App 라우터/네비게이션 배선 대기 — **App 모듈에서 처리**(사용자 확정 2026-08-28). → `App`.
- **서재(내 서재) 필터·정렬 영속화 복원 (사용자 확정 2026-08-28)** — V1은 필터·정렬을 UserDefaults에
  저장하고 앱 재실행 후 복원했다(`libraryFilterOption`·`librarySortOption`). V2는 저장/복원이 전무해 앱을
  껐다 켜면 초기화된다(Feature·App grep 0). 매 실행 초기화는 UX 후퇴라 **되살리기로 결정** — 경량
  영속화(UserDefaults 등)로 저장/복원하되 V1의 저장 키·구조를 그대로 복사하진 않는다(재설계). 근거·상세는
  `LibraryFeature/V1_BEHAVIOR_CONTRACT.md` 1.5·0-1. → `LibraryFeature`.
- **push 화면 재진입 재조회 복원 (횡단, 사용자 확정 2026-08-28)** — V1은 push 화면도 `viewWillAppear`마다
  서버 재조회했으나 V2는 `hasLoaded` 1회 가드로 성공 후 재조회하지 않는다. **push→pop→복귀 창에서 서버가
  바뀐 것(새 알림·다른 기기 읽음·외부 변경)이 미반영**되는 걸 없애기로 결정 — 복귀 시 재조회를 복원한다.
  대상은 **알림 목록/상세·타유저 프로필·전체 피드 목록·작품 상세** 등 push 계열. 단 스크롤 위치·낙관 반영
  보존을 깨지 않게 화면별로 조정(전체 피드 목록처럼 "비우고 처음부터"는 재검토). 근거: `NotificationFeature`
  1.1·0-1 / `UserPageFeature` 4.1·5.2·0-2 / `NovelDetailFeature` 0(1회 로드).
  ⚠️ **작품 상세는 실측 회귀 확인**(사용자 보고 2026-08-28: 작품 평가 후 상세 복귀 시 헤더 별점·집계 미갱신) —
  parity 복원이 아니라 관측된 회귀라 우선순위가 높다. → 다수 Feature.
- **크로스스크린 완료 피드백 재설계 (App 조정 계층, 사용자 확정 2026-08-28)** — V1은 `NotificationCenter` 배관
  (`feedEdited`·`NovelReviewed`·`BlockUser`)으로 다른 화면에서 끝난 일의 결과를 복귀 화면에 토스트로 알렸다
  ("수정 완료"·"평가 완료"·"차단했어요"). V2엔 이 배관이 없다. 위 push 재진입 재조회 복원과 **같은 App 배선 자리**에서
  콜백/이벤트로 재설계한다(싱글톤 NotificationCenter 답습 금지). 근거: `FeedFeature` 0절 15 / `NovelDetailFeature`
  6.5·0절 11 / `UserPageFeature` 4.6(소소 묶음 ①과 합류). → App + 다수 Feature.
- **알림 상세 본문 URL 자동 링크 복원 (사용자 확정 2026-08-28)** — V1 상세 본문은 `UITextView`
  `dataDetectorTypes=.link`라 평문 URL이 탭 가능했으나, V2 순수 `Text`는 평문 URL을 링크로 렌더하지 않는다.
  `AttributedString` 링크 감지로 복원. **선행 확인**: 서버 알림 본문에 실제 링크가 실리는지. 근거:
  `NotificationFeature` 2.3·0-2. → `NotificationFeature`.
- **타유저 USER-018('알 수 없는 유저') 전용 처리 복원 (사용자 확정 2026-08-28)** — V1은 `USER-018` 서버
  에러를 잡아 빈 프로필로 폴백했으나, V2는 `USER-015`(비공개)만 처리하고 018은 일반 로드 실패
  (`NetworkErrorView`)로 떨어져 재시도만 반복된다(잠재 회귀). 018 전용 "없는 유저" 처리를 복원한다. 근거:
  `UserPageFeature` 4.7·0-4. → `UserPageFeature`.
- **홈 선호장르 "설정했으나 추천 0건"도 설정 유도 카드로 (사용자 확정 2026-08-28)** — V2는 `PreferenceGenreNovelState`를
  `.noGenreSettings`(유도 카드) / `.novels([])`(섹션 숨김)로 나눴으나, 0건일 때도 V1처럼 유도 카드를 띄우기로(빈 자리보다
  행동 유도가 낫다). `.novels([])` 분기를 유도 카드로 합치거나 별도 케이스로 같은 카드 렌더. 근거: `HomeFeature` 2.5·0절 7.
  → `HomeFeature`.
- **소소한 V1 parity 복원 묶음 (사용자 확정 2026-08-28, 저우선)** — ① 타유저 차단 성공 시 "차단했어요"
  안내(토스트) 복원(`UserPageFeature` 4.6). ② 마이페이지 스크롤>0 시 네비바 "마이페이지" 타이틀 복원
  (`UserPageFeature` 1.8). ③ 생년 휠 상한 dynamic화 — 현재 `BirthYear.maxYear=2024` 하드코딩(V1도 2025
  하드코딩)이라 현재연도 기반으로(`ProfileDomain/BirthYear.swift`, `SettingFeature` 3.2·`OnboardingFeature`
  공용). ④ 작품 상세 피드 셀의 **탈퇴 유저(`userId == -1`) 프로필 탭 토스트** 복원(`NovelDetailFeature` 4.3 —
  Feed 0절 8·USER-018 폴백과 통일; V2 매퍼가 `-1`을 nil로 안 접는 함정은 계약서 4.3 참고). → `UserPageFeature`·`ProfileDomain`·`NovelDetailFeature`.

### 13. 판정 보류(논의 대기) → `docs/PENDING_DECISIONS.md`로 이관 (#222 C1/C2)

개발이 **단독으로 못 닫는 것**(백엔드 스펙·기획·디자인 판단)은 12절(되살리기/고치기로 **결정**됨)과 달리
**판정 자체가 열려 있어** 팀 논의로만 닫힌다. 흩어지지 않게 **[`docs/PENDING_DECISIONS.md`](PENDING_DECISIONS.md)
한 곳에 모았다** — 현재 1건(**개발 내부 재검토 1** — 1·2·3·4·5·6·8번은 닫힘, 그 문서 "닫힘 이력" 참조).
**외부 의존이 없어도 "실측 뒤 정하자"고 미룬 것 역시 그 문서(E절)에 둔다** — 열린 판정은 어디든 흩어두지 않는다.

## 열린 항목: AI 검증 체계(#205 축) 후속

AI 검증 체계(기계 게이트·CI·테스트 체계 — 지도 이슈 **#205**) 작업에서 파생된 후속. **코드 전수 점검·정리**(예: 3번 swift-format 전체 리포맷)처럼 대개 레포 전체를 훑는 대공사이거나, 게이트 안정화 후로 미룬 것이다. 착수 시 이슈로 승격한다. (번호는 이 절 안에서만 쓰는 지역 번호다 — 위 기능 목록과 별개. 다른 문서·메모리는 "TODO(AI 검증 후속) N번"처럼 절 이름을 함께 적어 참조한다.)

### 1. SettingFeature·CollectionFeature에 VM 테스트가 없다

- **무엇**: 두 Feature 모두 `.tests`를 선언했으나 `Tests/`에 실제 테스트가 없었다. 처리 방식이 갈린다:
  - **SettingFeature**: `Tests/`가 비어(`.gitkeep`만) 빈 xctest 번들이 "실행 파일 없음"으로 로드 실패 → #210에서 **`.tests` 제거**. VM 테스트 생기면 재선언.
  - **CollectionFeature**: `Tests/`에 `.swift` 파일이 0개인데 `.tests`를 선언해 **`tuist generate`가 "Tests/** 글롭 무효"로 워크스페이스 전체를 깨뜨렸다**(모든 모듈 테스트가 Generate 단계에서 실패, develop 전 CI 정지) → #217에서 **placeholder 테스트 1개 추가**(`CollectionFeaturePlaceholderTests`, `.tests` 유지). ⚠️ **`.tests`는 Tests에 통과 테스트가 최소 1개 있을 때만 선언할 것** — 빈 채 선언하면 (빈 번들 로드 실패 또는) generate 자체를 막아 전 CI를 세운다.
- **왜 지금 안 했나**: VM 테스트 작성은 별건(지도 이슈 #205 축 B-B2 "Feature VM TDD"). VM 계약을 파악해 써야 해 청소 범위 밖.
- **어디를 고치나(할 때)**: 해당 `Feature/<Module>/Tests/`에 VM 테스트 추가 + `Project.swift` targets에 `.tests` 재선언(필요 시 `testDependencies`도). `NovelReviewFeature`가 선례.

### 2. swift-format 게이트를 "변경 파일만 report-only" → "레포 전체 --strict"로 격상 (전체 1회 리포맷)

- **무엇**: A3(#215)에서 swift-format 게이트를 **"변경 파일만·report-only"** 로 착지시켰다. 레포 전체(886파일)를
  swift-format 스타일로 정렬한 적이 없어, 튜닝 설정(`.swift-format`)으로도 ~8,500 findings(대부분 **끌 수 없는
  레이아웃** — 줄끝공백·들여쓰기·spacing)이 남아 있다. 이걸 `swift format format -i`로 일괄 정렬해 **warning 0**으로
  만들면 게이트를 **레포 전체 `--strict`** 로 격상하고 `Swift Format`을 required check로 걸 수 있다(더 강함).
- **규모(실측 2026-08-26)**: `format -i`가 **441/886 파일·~7,250줄**(3,967+/3,290−) 변경. 자동수정 후 **남는 수동
  경고는 14곳뿐**: `AlwaysUseLowerCamelCase` 10(식별자 개명은 자동 불가)·`NoBlockComments` 2·
  `ReplaceForEachWithForLoop` 1·`AvoidRetroactiveConformances` 1.
- **왜 지금 안 했나**:
  1. **열린 PR 5개**(#200·#199·#193·#189·#188, 전부 Feature)가 **전부 리베이스 충돌 대상** → 대공사(리포맷)와
     게이트 도입을 분리한다. A3 자체가 "변경 파일만"인 이유가 이것(리포맷 없이 새 코드부터 보호).
  2. 441파일엔 `forEach→for`·중복 init 삭제·세미콜론 줄분리 같은 **AST 변형**이 섞여 있어 **빌드+테스트 전수
     검증**이 필수. 게이트 착지와 한 PR에 섞으면 문제 원인 규명이 어렵다.
- **어디를 고치나(할 때)**: 별도 PR로 ① `swift format format -i` 전체 적용 + 수동 14곳 처리 + **전체 빌드·테스트
  검증** → ② `test.yml`의 `format-lint`를 `lint-changed.sh --strict`(또는 whole-repo `swift format lint --strict`)로
  바꾸고 ③ develop 초록 확인 후 `Swift Format`을 required로 승격. **열린 PR이 정리된/저트래픽 창에 팀 공지 후 일괄**로.
- **놓치기 쉬운 것**: 규칙 allowlist(OrderedImports off 등)의 정본은 루트 **`.swift-format`** 이다 — 리포맷도 반드시
  이 설정으로 해야 문서화된 규약(레이어 기반 import 순서)을 안 깨뜨린다. 기본 설정으로 돌리면 알파벳 정렬로 규약 파괴.

### 3. A2 ArchLint — DTO 네이밍 규칙(`dto-naming`)만 남음 (VM·UseCase·Repository·Factory는 완료)

- **무엇**: A2 네이밍 앵커 규칙 5종 중 **4종은 #215 후속 PR에서 도입 완료**(error·baseline 초록):
  `vm-naming-reverse`(@Observable class ⇔ `*ViewModel`)·`usecase-naming`(protocol=`*UseCase`)·
  `repository-naming`(protocol=`*Repository`)·`factory-existence`(각 Data 모듈 public `*DataFactory`).
  **`dto-naming`(DTO 파일=`*Response`/`*Request`/`*Query`)만** 남겼다.
- **왜 뺐나(정확한 블로커, 실측 2026-08-26)**: 헤드라인/파일명 기준 접미사 검사로 짜면 baseline이 초록이 아니다 —
  실제 위반이 남는다:
  1. **`KakaoLoginRequestHeader`**(`AuthData/DTO/Request/`) — 헤드라인 자리(파일=타입명)인데 요청 **헤더** DTO라
     `*Request`가 아니라 `*Header`로 끝난다. 정당한 이름이라 규칙이 잡으면 오탐이 된다.
  2. **`QueryItem/` 폴더**(FeedData만) — 다른 모듈의 `Query/`와 폴더명이 달라 "DTO 다음 디렉토리=접미사" 로직이
     깨진다(안의 파일은 `*Query`인데 폴더는 `QueryItem`). 폴더 관례부터 통일해야 함.
  (참고: 응답 내 배열 원소 sibling struct 3종 — `BlockdUser`·`ProfileAvatar`·`GenrePreferences` — 은
   "파일명=헤드라인 struct만 검사" 방식이면 **자동 제외**돼 더는 블로커가 아니다.)
- **어디를 고치나(할 때)**: ① `QueryItem/`→`Query/` 폴더 통일(FeedData) + ② `KakaoLoginRequestHeader`의
  관례 확정(rename or 명시 예외) → ③ `Tooling/ArchLint`에 `dto-naming` 규칙 추가(선례: `ProtocolNamingRule`)
  + 자체 테스트. CI `Architecture Rules` job이 이미 돌리므로 배선 불필요.
  - 대안: 규칙을 **warning(리포트만)** 으로 두면 위 예외를 정리하지 않고도 도입 가능(ArchLint의 "프록시→warning" 철학).
- **덤(별개 정리감)**: `BlockdUser`는 `BlockedUser` **오타**(e 누락, `SocialData/DTO/Response/BlockedUserResponse.swift`).
  접미사 규칙 대상은 아니나 함께 손볼 때 고칠 것.

### 4. A4 Swift 6 — 잔여 concurrency 경고 3건 + Feature @MainActor 완주

- **무엇**: #219(A4 1~4단계)에서 프로덕션 strict concurrency 경고를 **249→3**으로 줄였다(Domain·Core·UI·Data=0).
  남은 **3건은 전부 `NovelDetailFeature`의 `TopBounceDisabler`**(`NovelDetail/NovelDetailView.swift:685·687·688`):
  `UIScrollView.observe(\.contentOffset)` KVO 클로저가 main-actor 격리 프로퍼티(`contentOffset`)에 key path를
  걸고 읽고/쓴다.
- **왜 이번에 안 했나**: 이 클램프 로직은 **서브틀한 버그 이력이 있고 시뮬레이터 자동화로 검증이 안 되는**
  스크롤 동작(모듈 `CLAUDE.md`의 `TopBounceDisabler`·`enableSwipeBack` 항목 참고)이라, `MainActor.assumeIsolated`
  래핑이 동작을 바꾸지 않는지 **사람이 기기에서 직접 밀어** 확인해야 안전하다. 자동 세션에서 블라인드로 손대지 않았다.
- **시도 결과(2026-08-27, 실측 — `assumeIsolated`는 실패로 판명)**: 클로저 본문을 `MainActor.assumeIsolated`로
  감싸고 `Coordinator`를 `@MainActor`로 올려 **경고 3→0·빌드 성공**까지 갔으나, **실기기에서 상단 클램프가
  깨졌다**(하단 bounce만 정상, 상단 over-scroll이 안 잡힘). 진단 로그상 `y=0` 쓰기는 매 프레임 반영되는데도
  UIScrollView bounce 애니메이션이 덮었다 — `assumeIsolated`가 KVO 콜백 동기 실행 순서를 바꾼 것으로 추정.
  **되돌렸다**(원본 비격리 유지, 경고 3건 감수). 재현·상세는
  [NovelDetailFeature CLAUDE.md](../Projects/Feature/NovelDetailFeature/CLAUDE.md)의 `TopBounceDisabler` 항목.
- **다음 시도 방향(보류)**: `assumeIsolated` 없이 mode 6 경고를 없애는 길을 찾아야 한다 — `@preconcurrency`/
  `nonisolated` 우회 검토, 또는 이 KVO를 UIKit 컨테이너로 옮겨 SwiftUI 경계 밖에서 처리, 최후엔 이 모듈만
  mode 6 예외. Feature mode 6 승격(5번 6단계) 착수 시 이 화면을 별도로 다룬다. 경고 3건은 report-only라 빌드 무해.

### 5. A4 Swift 6 — 경고 0 레이어 mode 6 승격 ✅완료 / Feature·App은 대기 (5·6단계)

- **완료(5단계)**: 경고 0을 달성한 **Core·Domain·Data·UI 32개 모듈**의 Sources 타깃을 **Swift 6 language
  mode**(`SWIFT_VERSION = 6`)로 승격했다 — concurrency 위반이 이제 warning이 아니라 **컴파일 error**다
  (로컬 Xcode·CI 모두 자동으로 막음). 32모듈 전부 mode 6에서 error 0으로 빌드됨을 실측 확인(fresh DD 모듈 스킴 순회).
  - **구현**: `Tuist/ProjectDescriptionHelpers/Project+Templates.swift`의 `swift6SourcesSettings`를
    `makeBaseTargets`의 **Sources 타깃에만** 주입(Core·Domain·Data·UI create 함수에서 전달, Feature는 미전달).
    `env.baseSetting`(전역)이 아닌 이유: #219는 Sources만 청소했고 Demo/Testing/Tests는 strict concurrency
    미청소라, 전역/프로젝트 세팅에 얹으면 그쪽이 error로 깨진다. Sources 타깃 한정으로 회피.
  - **왜 scan.sh --strict CI가 아니라 pbxproj 직접 승격인가**: 컴파일러 error가 report-only CI 게이트보다
    강하고 빠르다(로컬 빌드에서 즉시, 전 모듈 재컴파일하는 무거운 CI job 불필요). 승격된 레이어만큼 그
    존재 이유가 사라져 → **43모듈 승격 후 `Tooling/StrictConcurrency/`와 `strict-concurrency` CI job을 제거함**(아래).
- **6단계 진행 — Feature 11개 승격 완료 (NovelDetail 제외)**: `createFeatureModule`에 `enableSwift6: Bool = true`
  파라미터를 추가해 11개 Feature Sources를 mode 6으로 올렸다. **NovelDetailFeature만 `enableSwift6: false`**
  (TopBounceDisabler KVO 3건 미해결 → 위 4번). 검증: 11개 전부 **Demo 포함 BUILD SUCCEEDED·Sources error 0**
  실측(fresh DD) + Home·Library·Search Demo 시뮬레이터 스모크 정상(런타임 무회귀 — 코드 무변경 승격이라 예상대로).
- **남은 것**: ① **NovelDetailFeature**(위 4번 KVO 해결 후 `enableSwift6: true`) ② **App(WSS-iOS)**(Feature 전부가
  mode 6이 된 뒤 마지막) ③ **각 모듈 Demo/Testing/Tests**(별건 — 예: Demo Mock UseCase의 `store`가 non-Sendable이라
  mode 6 오버라이드 시 error. Sources 승격엔 무관하나 Demo까지 올리려면 정리 필요).
- **정리 완료(6단계와 함께)**: `Tooling/StrictConcurrency/scan.sh`·`README.md`와 `test.yml`의
  `strict-concurrency`(Swift 6 Readiness) job·주간 `schedule` cron을 **제거함**. 근거: 43모듈이 mode 6라
  컴파일러가 회귀를 error로 막고(report-only 스캐너보다 강함), 남은 mode 5(NovelDetail·App·Demo/Tests) 승격은
  "그 스킴을 mode 6으로 직접 빌드"가 scan.sh의 `complete`-warning 집계보다 정확하다(warning 0 ≠ mode 6 error 0).
- **Feature @MainActor 완주(선택)**: #219는 UseCase/Entity를 Sendable로 만들어 Feature "sending" 경고를
  cascade로 없앴다(@MainActor 없이). Feature를 mode 6으로 올릴 때 VM을 `@MainActor`로 명시하는 게 정석이므로
  (로드맵 3단계 본래 취지), 그때 12개 Feature VM에 @MainActor를 붙이고 화면별로 검증한다.
