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

### 8. 컬렉션 "공유하기"가 아직 착수되지 않았다(TODO 스텁 유지)

- **무엇**: `CollectionDetailView`의 "공유하기" 버튼(`shareTapped`)이 여전히 TODO 스텁이다. 카카오톡
  공유(`KakaoSDKShare`/`KakaoSDKTemplate`)로 착수할 계획은 세워뒀다 — 스코프는 **카카오톡 공유만**(일반
  iOS 공유시트·링크 복사, 딥링크는 별도 후속)로 사용자와 확정했고, 상세 구현 계획(파일별 변경 지점,
  `Tuist/Package.swift`의 `.framework` 강제 필요성, Demo 앱 `KakaoSDK.initSDK` 초기화 필요성 등)이
  세션 기록에 남아있다.
- **결과**: "공유하기"를 눌러도 아무 반응이 없다(공개 컬렉션에서만 버튼이 보임).
- **어디를 고치나**: `Projects/Feature/CollectionFeature/Sources/CollectionDetail/CollectionDetailView.swift`/
  `CollectionDetailViewModel.swift`, `Tuist/Package.swift`(`KakaoSDKShare`/`KakaoSDKTemplate`
  `.framework` 등록), `Projects/Feature/CollectionFeature/Project.swift`,
  `Projects/Domain/BaseDomain/Sources/AppURL.swift`(임시 공유 링크 상수).
- **왜 지금 안 했나**: 사용자 결정 — 같은 세션에서 컬렉션 "수정" 기능을 먼저 넣기로 하고 공유는
  후속으로 미뤘다(2026-08).
- **놓치기 쉬운 것**: 착수 시 `KakaoSDK*`는 반드시 `Tuist/Package.swift`의 `productTypes`에서
  `.framework`(dynamic)로 강제해야 한다 — 안 그러면 `OnboardingFeature`가 이미 겪은 것과 같은
  `SdkError.ClientFailed(.MustInitAppKey)` 크래시가 난다(`OnboardingFeature/CLAUDE.md` 참고). Demo
  앱도 App과 별개 프로세스라 `KakaoSDK.initSDK`를 자체 호출해야 한다(`OnboardingFeatureDemoApp.swift`
  선례). 카카오 공유 카드의 `Content.imageUrl`은 필수 필드라 대표 작품 표지가 없는 컬렉션을 위한
  원격 기본 이미지 URL을 먼저 정해야 한다.

### 9. 컬렉션 상세 작품 탭이 작품 상세로 연결되지 않는다

- **무엇**: `CollectionDetailView`의 작품 그리드 셀을 탭하면 `onNovelTapped(NovelID)` 콜백까지는
  발화하지만, `CollectionFeatureFactory`(`makeCollectionListView`/`makeCollectionDetailView`)를
  실제로 호출하는 곳(App 조립 계층)이 아직 없어 그 콜백을 받아 `NovelDetailFeature`로 연결해주는
  배선이 없다. Demo는 콘솔 로그만 찍는다(`handleNovelTapped`).
- **결과**: 컬렉션 상세에서 작품을 탭해도 아무 화면 전환이 일어나지 않는다.
- **어디를 고치나**: App이 `CollectionFeatureFactory.makeCollectionListView`/`makeCollectionDetailView`를
  조립하는 지점에서 `onNovelTapped: { novelID in ... }`를 `NovelDetailFeatureFactory.makeView(...)`로
  push하도록 연결한다(다른 화면의 `onXxxTapped` 콜백들과 동일한 배선 방식 — `NovelDetailFeature`의
  `onAuthorTapped` 등 이미 있는 App 배선 선례를 따를 것).
- **왜 지금 안 했나**: Feature 모듈끼리는 서로 import 못 해(`App → Feature → Domain` 단방향) 이
  연결은 원래 App의 몫이다. #196에서 App의 첫 실전 조립이 이뤄졌지만 범위는 로그인·온보딩뿐이었고,
  컬렉션 화면 조립(`CollectionDataFactory` 등)과 메인 탭 라우팅은 아직 없어 지금은 콜백 시그니처만
  뚫어두고 실제 연결은 메인 탭이 생기는 후속 이슈로 미뤘다(2026-08).
- **놓치기 쉬운 것**: `onNovelTapped`는 VM을 거치지 않고 `CollectionDetailView`가 탭 즉시 직접
  호출한다(`NovelDetailFeature.onAuthorTapped`와 동일 패턴) — App 쪽에서 이 콜백을 받을 때도 VM
  상태를 개입시키려 하지 말 것.

### 10. 콜드스타트 시 저장된 세션을 재사용하지 않는다

- **무엇**: `ContentView.route`가 항상 `.onboarding`으로 시작한다(`@State private var route: Route = .onboarding`).
  Keychain(`DefaultTokenStore`)에 유효한 토큰이 남아있어도 앱을 재실행하면 확인 없이 다시 인트로부터
  시작한다.
- **결과**: 로그인 성공 시 토큰이 저장되고 401 자동 갱신도 연결돼 있지만(#196), 그 지속성은 **같은
  프로세스 안에서만** 유효하다 — 강제 종료 후 재실행하면 토큰이 살아있어도 도로 로그인해야 한다.
- **어디를 고치나**: `ContentView.init` 또는 `body` 진입 시점에서 기존 세션(access/refresh token)
  유효 여부를 확인해, 있으면 `route`를 `.main`으로 시작하도록 분기를 추가한다. ⚠️ `tokenStore`는
  현재 `AppDependencies.init()` 내부 지역 변수라 `dependencies.tokenStore`로 바로 못 꺼낸다 — 착수
  시 먼저 인스턴스 프로퍼티로 승격해야 한다.
- **왜 지금 안 했나**: #196 체크리스트 범위 밖(사용자 확인, 2026-08) — `.main`이 여전히 placeholder라
  세션을 복원해도 갈 곳이 없어 지금 체감 피해가 없다. 메인 탭이 실제로 생기는 후속 이슈에서 함께
  다룬다.

### 11. `UserPageFeatureDemoApp`의 마이페이지 편집·설정·서재 전환이 콘솔 로그로만 남아있다

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

### 12. 작품 평가 화면의 키워드 선택이 draft에 반영되지 않는다

- **무엇**: `NovelReviewFeature`의 키워드 서치바를 탭하면 `KeywordFeature`의 `SearchKeywordView`가
  시트로 뜨긴 하지만(#197, `NovelReviewFactory.makeView(keywordSearchSheet:)`), 그 시트에서 키워드를
  골라도 **결과가 평가 화면(`NovelReviewDraft`)으로 돌아오지 않는다.** 선택된 키워드 칩을
  `NovelReviewView`에 표시하는 UI도 아직 없다.
- **결과**: 사용자가 키워드를 골라도(시트 안 `state.selectedKeywords`엔 남음) "완료"로 평가를 저장하면
  키워드 없이 저장된다 — 시트가 눈속임처럼 보인다.
- **어디를 고치나**:
  - `Projects/Feature/KeywordFeature/Sources/SearchKeywordView.swift`의 하단 액션바 "N개 선택" 버튼
    (지금 빈 액션, `// TODO: - 키워드 선택 완료 로직 추가`)에 **선택 완료를 밖으로 알리는 콜백**을 추가해야
    한다. `KeywordFeatureFactory.makeSearchKeywordView`도 그 콜백을 받아 전달하도록 시그니처 확장 필요.
  - `Projects/Feature/NovelReviewFeature/Sources/NovelReview/NovelReviewView.swift`의
    `keywordSearchSheet: () -> some View` 자리는 **콘텐츠만** 받고 결과를 받을 통로가 없다 — 시트 dismiss
    + 선택 키워드 배열을 같이 받는 형태로 `NovelReviewFactory.makeView`의 파라미터 설계를 다시 해야 한다
    (예: `keywordSearchSheet: (@escaping ([Keyword]) -> Void) -> some View`처럼 완료 콜백을 시트
    빌더에 넘기는 방식, 또는 다른 형태 — 설계는 착수 시 다시 검토).
  - `NovelReviewDraft`에 키워드 필드 자체가 있는지도 확인 필요(`NovelReviewDomain`).
- **왜 지금 안 했나**: #197 범위(키워드 서치바를 시트로 띄우는 것)를 사용자가 먼저 좁혀 요청 —
  선택 결과 반영은 후속 작업으로 명시적으로 미룸(2026-08-20).
- **놓치기 쉬운 것**: `KeywordFeature`는 이 화면 하나만을 위해 만들어진 게 아니라 범용 키워드 선택기라,
  콜백 시그니처를 바꾸면 다른 잠재 소비처에도 영향(현재는 `NovelReviewFeature`가 유일한 소비처).
- **추가 메모(2026-08-20)**: 위에서 언급한 `keywordSearchSheet:` 시트 연결 자체를 사용자가 일단 코드에서
  전부 되돌렸다(제네릭 `@ViewBuilder` 파라미터 방식이 맞는 설계인지, `AnyView` 타입소거가 나은지 결론을
  못 내려서) — **제네릭 vs `AnyView` 설계도 아직 미정, 다음 착수 시 처음부터 다시 정할 것.** 그러니 이
  항목 착수 시엔 위 "어디를 고치나"의 `keywordSearchSheet` 관련 서술은 더 이상 코드에 존재하지 않는
  상태에서 다시 설계해야 한다(시트 연결 자체부터 재구현).

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
