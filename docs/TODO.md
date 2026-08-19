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
