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

## 열린 항목: AI 검증 체계(#205 축) 후속

AI 검증 체계(기계 게이트·CI·테스트 체계 — 지도 이슈 **#205**) 작업에서 파생된 후속. **코드 전수 점검·정리**(예: 3번 swift-format 전체 리포맷)처럼 대개 레포 전체를 훑는 대공사이거나, 게이트 안정화 후로 미룬 것이다. 착수 시 이슈로 승격한다. (번호는 이 절 안에서만 쓰는 지역 번호다 — 위 기능 목록과 별개. 다른 문서·메모리는 "TODO(AI 검증 후속) N번"처럼 절 이름을 함께 적어 참조한다.)

### 1. SettingFeature에 VM 테스트가 없다 (`.tests` 선언을 되돌림)

- **무엇**: SettingFeature는 `.tests`를 선언했으나 `Tests/`가 비어(`.gitkeep`만) 있어 빈 xctest 번들이 "실행 파일 없음"으로 로드 실패했다 → #210에서 `.tests`를 제거해 CI에서 뺐다. 즉 지금 SettingFeature는 **테스트 0개**.
- **왜 지금 안 했나**: VM 테스트 작성은 별건(지도 이슈 #205 축 B-B2 "Feature VM TDD"). 여러 `SettingViewModel`의 계약을 파악해 써야 해서 #210(기존 실패 청소) 범위 밖.
- **어디를 고치나(할 때)**: `Projects/Feature/SettingFeature/Tests/`에 VM 테스트 추가 + `Project.swift` targets에 `.tests` 재선언(필요 시 `testDependencies`도). `NovelReviewFeature`가 선례.

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
