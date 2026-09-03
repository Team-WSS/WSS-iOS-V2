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

### 4. 최종 이관(cutover) 시 운영 앱의 Bundle ID·서명 팀으로 교체해야 한다

- **무엇**: WSS-iOS-V2는 지금 운영 중인 기존 앱을 **나중에 완전히 대체**할 새 프로젝트다(사용자 확정).
  백엔드는 이미 같은 서버/DB를 공유한다. Apple 로그인 유저 식별자(`sub`)는 **(Apple Developer 팀 ID +
  Bundle ID)** 조합에 고정되고, Kakao 로그인은 App Key(Release 빌드가 `Config/Config_Release.xcconfig`의
  운영 `KAKAO_APP_KEY`를 씀 — Debug는 #241부터 별도 테스트 앱 키라 이 이관 대상이 아니다)는 같아도
  SDK가 런타임에 **호출 앱의 Bundle ID·서명 키해시가 Kakao 콘솔의
  iOS 플랫폼 등록값과 일치하는지** 검사한다. 이 값들이 운영 앱과 다른 채로 배포하면 기존 유저가
  로그인해도 **다른 계정으로 인식**된다.
- **결과**: 백엔드가 공유돼 있어 별도 계정 마이그레이션 로직은 필요 없지만, 아래 항목이 정확히 안 맞으면
  기존 유저의 Apple/Kakao 로그인이 "신규 가입"으로 잘못 처리된다.
- **✅ 완료(2026-08-29, 코드 반영)**: V1 레포(별도 클론)의 `project.pbxproj`를 직접 대조해 실제 값을
  그대로 옮겼다.
  - `Plugins/EnvironmentPlugin/ProjectDescriptionHelpers/ProjectEnvironment.swift`에
    `debugBundleId`/`releaseBundleId`/`appleDeveloperTeamID`(V1과 동일한 실제 값 — 값 자체는 `env`
    선언부 참고) 추가.
  - `Projects/App/Project.swift`의 Debug/Release 구성 각각에 `PRODUCT_BUNDLE_IDENTIFIER`·
    `CODE_SIGN_STYLE`(Manual)·`CODE_SIGN_IDENTITY`(기본 `Apple Development`, 실기기(`sdk=iphoneos*`)만
    `iPhone Distribution`)·`DEVELOPMENT_TEAM`(실기기만)·`PROVISIONING_PROFILE_SPECIFIER`(실기기만,
    `match AppStore <bundleId>`)를 V1과 동일하게 오버라이드.
  - `tuist generate` + 시뮬레이터 빌드 성공까지 검증.
  - Team ID는 비밀값이 아니다(프로비저닝 프로파일·배포 앱 서명 정보에 이미 공개돼 있고, 이것만으론
    서명 권한이 없음) — 평문 커밋 문제없음, V1도 동일하게 평문.
- **어디를 고치나(남은 것, 컷오버 시점에)**:
  1. ~~Bundle ID 교체~~ ✅ 위에서 완료.
  2. ~~`DEVELOPMENT_TEAM` 추가~~ ✅ 위에서 완료(fastlane match도 이후 도입 완료 — 아래 참고).
  3. Apple Sign-in capability는 운영 Bundle ID의 App ID에 이미 켜져 있을 것 — 신규 등록 불필요, 확인만.
  4. Kakao Developers 콘솔의 해당 앱(App Key 그대로) → 플랫폼 → iOS에 운영 Bundle ID + **새로 서명한
     배포 인증서의 키해시**가 등록돼 있는지 확인/추가.
  5. App Store Connect에 **운영 앱과 정확히 같은 앱 레코드**로 새 빌드 업로드(별도 신규 리스팅 금지 —
     기존 유저가 일반 업데이트로 받아야 리뷰·랭킹·설치기반이 유지됨, 사용자 확정).
  6. 컷오버 직전, 실제 배포 서명으로 실기기에서 Apple/Kakao 로그인이 "기존 계정 인식"으로 뜨는지
     서버 응답으로 리허설 검증.
- **✅ fastlane 도입 완료(2026-08-29)**: 저장소 루트에 `Gemfile` + `fastlane/`(`Appfile`/`Matchfile`/
  `Fastfile`)를 V1과 같은 구조로 가져왔다 — `Matchfile`은 V1과 **같은 인증서 저장소**
  (`git@github.com:Team-WSS/WSS-iOS-Certificates.git`)를 그대로 재사용한다(같은 Apple Developer
  팀이라 컷오버 시점에 V1의 운영 인증서를 그대로 이어받기 위함). `Fastfile`에 실기기 개발
  서명만 동기화하는 `sync_dev_certificates` lane을 새로 추가했다 — 이게 지금 당장 막힌
  "프로비저닝 프로파일 없음" 문제의 실제 해결책이다.
  - **✅ `debug_beta` 아카이브→TestFlight 업로드까지 실제로 성공(2026-08-29, `archive-debug` 스킬로
    실행)** — 애초 예상과 달리 App Store Connect에 디버그 앱 레코드가 **이미 존재**했다
    (기존 TestFlight 빌드 `1.9.4`도 있었음 — "미검증" 우려는 기우였다). 다만
    처음부터 한 번에 되지는 않았고, 이 과정에서 이 프로젝트에 원래 있던(fastlane과 무관한) App Store
    제출 준비 공백들을 실측으로 걷어냈다 — 자세한 내용·재발 방지 포인트는
    [Projects/App/CLAUDE.md](../Projects/App/CLAUDE.md)의 "앱 아이콘·버전 정보는 시뮬레이터 빌드만으론
    검증되지 않는다" 항목 참고(`resources:` 누락으로 아이콘이 빌드에 안 들어가던 것, Debug/Release
    아이콘 분리, `TARGETED_DEVICE_FAMILY`, `CFBundlePackageType`/`UISupportedInterfaceOrientations`,
    Apple Generic Versioning 설정까지). `release_beta`/`release` lane 자체는 아직 미실행(스킴만
    `WSS-iOS-RELEASE`로 다를 뿐 같은 경로라 성공 가능성 높음, 실측은 아직 안 함).
  - **⚠️ 컷오버 전 확인 필요(2026-08-29 wss-pr-reviewer 지적)**: `AppIcon.appiconset`/`AppIcon-Debug.appiconset`의
    1024×1024 PNG 둘 다 알파 채널을 포함한다(`sips`로 실측) — TestFlight 내부 업로드는 통과했지만
    정식 App Store 심사(`release` lane)에서는 마케팅 아이콘의 투명도가 거부 사유가 될 수 있다.
    컷오버 전 알파 제거된 PNG로 교체할 것.
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

- **무엇(해소)**: "공유하기"가 **카카오 공유 카드(`KakaoSDKShare`, 콘솔 커스텀 템플릿 — #241부터
  `KakaoSDKTemplate`/기본 템플릿 아님, 카드 자체를 탭하면 →
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
  `CollectionDetailView.shareButton`(시트 재도입) + `CollectionKakaoShare.multiThumbnailArgs`(콘솔
  커스텀 템플릿의 웹 링크 변수, #241부터 `makeTemplate`/`Link.webUrl`은 없음).

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

### 12. V1 parity 판정(#222 C1)에서 "되살리기/고치기로" 결정됐으나 미룬 것들

C1(#222) V1 동작 계약 추출 중 ❓Unknown으로 잡힌 항목을 사람이 판정한 결과, **되살리거나 고치기로 결정됐지만**
추출 PR 범위(문서화)를 벗어나 미룬 것. 상세·근거·인용은 각 모듈 `V1_BEHAVIOR_CONTRACT.md`. (판정 세션 2026-08-28)
서버 요청 파라미터 매핑의 V1↔V2 교차 종합(C2)은 [`docs/V1_PARAM_MAPPING_C2.md`](V1_PARAM_MAPPING_C2.md)가 정본.

- **Amplitude 애널리틱스 횡단 재도입** — V1은 홈·작품상세·검색·키워드 등 곳곳에 이벤트를 심었다. V2 전무. 화면별
  계약이 아니라 **횡단 인프라**라 별도 이슈로 승격 대상. → 다수 모듈.
- **UserPage 계열 인증 만료 로그인 라우팅 배관** — 타유저 프로필·활동 피드엔 `requiresAuthentication` 신호·콜백
  배관 자체가 없어 세션 만료가 조용히 삼켜진다(#236 리뷰에서 확인된 기존 공백 — 재조회 추가로 무표현
  경로가 하나 더 늘었다). Feature "인증 만료 처리 계약"대로 신호+콜백+App 라우팅 배선. → `UserPageFeature`.

(검색 네비게이션 5경로·push 재진입 재조회(작품 상세 피드 포함)·크로스스크린 완료 피드백은 **#236에서 해소**돼 지웠다 —
현재 동작의 정본은 각 모듈 `CLAUDE.md`와 `App/CLAUDE.md`의 크로스스크린 피드백 채널 항목.)

### 13. 판정 보류(논의 대기) → `docs/PENDING_DECISIONS.md`로 이관 (#222 C1/C2)

개발이 **단독으로 못 닫는 것**(백엔드 스펙·기획·디자인 판단)은 12절(되살리기/고치기로 **결정**됨)과 달리
**판정 자체가 열려 있어** 팀 논의로만 닫힌다. 흩어지지 않게 **[`docs/PENDING_DECISIONS.md`](PENDING_DECISIONS.md)
한 곳에 모았다** — 현재 1건(**개발 내부 재검토 1** — 1·2·3·4·5·6·8번은 닫힘, 그 문서 "닫힘 이력" 참조).
**외부 의존이 없어도 "실측 뒤 정하자"고 미룬 것 역시 그 문서(E절)에 둔다** — 열린 판정은 어디든 흩어두지 않는다.

### 14. #236 앱 배선의 실기기/수동 QA 점검 목록 (시뮬레이터 자동화 한계로 미실측)

- **무엇**: #236 배선 작업에서 시뮬레이터 자동화로 검증할 수 없었던 경로들. 코드·빌드 검증과 화면 표시
  실측은 끝났고 **상호작용 런타임 실측만** 남았다. 출시 전 QA(실기기 리허설) 때 손으로 확인하고 항목별로 지울 것.
  1. **강제 업데이트 알럿 → "업데이트" 버튼**: App Store 앱이 열리는지. **실기기 전용** — 시뮬레이터엔
     App Store 앱이 없어 어떤 스토어 링크도 끝까지 못 연다(URL 자체는 `curl` 200 + 웹소소 앱 레코드
     타이틀로 확인 완료). 서버 최소 버전을 못 올리면 `ContentView.handleBootstrapOutcome`에 outcome을
     임시 강제하는 방법으로 재현한다(#236 작업 중 썼던 방식 — 커밋 전 되돌릴 것).
  2. **약관 재동의 알럿 → "동의하러 가기" 탭**: 알럿이 닫히고 약관 시트로 전환되는지. WSSAlert 버튼은
     접근성 트리에 없어 자동화 탭이 불가했다(알럿·시트 각각의 **표시**는 시뮬레이터 실측 완료).
  3. **토큰 없는 콜드 스타트 → 온보딩 낙착**: 로그아웃(또는 앱 삭제 후 재설치) 상태로 앱을 켜면
     스플래시 뒤 온보딩으로 가는지(`BootstrapOutcome.intro`). 시뮬레이터 세션을 지우면 재로그인이
     필요해 미실측.
  4. **push 재진입 재조회(#236 4단계)**: ① 알림 목록 → 상세 갔다 복귀 시 목록 갱신(새 알림·타기기
     읽음 반영) ② 타유저 프로필 → 피드 상세 갔다 복귀 시 프로필·활동 갱신 ③ 타유저 전체 피드 목록은
     **밖으로 나가는 경로가 아직 없어**(셀 탭·프로필·연결 작품 전부 미배선/TODO) 복귀 자체가 없다 — 배선되면
     그때 실측. (작품 상세는 제외 — 헤더 재조회는 #221, 피드 재조회는 #236에서 시뮬레이터 실측 완료(작성
     복귀 시 size=보던 개수 요청·목록 반영·헤더 집계 갱신 확인).)
  5. **피드 탭 재진입 = 다녀온 셀만 상세 동기화(2026-09-03, `FeedFeature/CLAUDE.md` 화면 동작 계약)**: 시뮬레이터에서
     ① 깊이 스크롤 → 상세 좋아요/수정/삭제 → 복귀 시 스크롤 유지 + 그 셀만 반영, 홈 탭 왕복 시 요청 0건은 실측 완료.
     실기기에서 다시 볼 것은 ② 다른 탭 작품 상세 "나도 한마디"로 작성 → 피드 탭에 새 글이 이미 맨 위
     ③ 당겨서 새로고침 인디케이터가 완료까지 유지 ④ 내 피드 0건 계정 복귀 시 빈 뷰 깜빡임 없음.
  6. **콜드 스타트 세션 복원 이상 징후(2026-09-03 시뮬레이터, 확인 필요)**: 카카오/애플로 로그인해 홈까지 본 직후 앱을
     종료·재실행하자 `/keywords`가 `401 AUTH-001(유효하지 않은 토큰)`을 받았고 `/reissue` 시도 없이 온보딩으로 갔다
     (같은 세션에서 두 번 재현). 로그인 직후 저장된 토큰이 왜 콜드 스타트에서 무효인지(저장 누락? 재발급 조건?) —
     피드 탭 작업 중 부수 관찰이라 손대지 않음. 출시 전 실기기에서 로그인 → 강제 종료 → 재실행으로 반드시 확인.

### 15. 앱 전역 "피드 변경 로그" — 화면 간 좋아요/삭제 즉시 반영 (보류, 출시 후 검토)

- **무엇**: 피드를 건드린 사건(상세 방문·좋아요·삭제·수정·작성)을 FeedDomain의 순번 있는 인메모리 로그에
  기록하고, 각 피드 목록이 진입 시 "마지막 동기화 이후 변경된 ID ∩ 자기 목록"만 상세 API로 셀 교체하는
  구상(2026-09-03 설계 논의). 지금은 **다른 화면에서 한 좋아요·삭제가 피드 탭에 즉시 반영되지 않는다**
  (당겨서 새로고침으로 복구 — 판정된 절충, V1도 동일).
- **보류 이유**: ① 작품 상세·유저 프로필은 재진입 전체 재조회가 이미 셀 동기화의 상위호환(스크롤 보존 +
  타 유저 변경까지 반영)이라 실익이 피드 탭 하나뿐이고, ② Domain 엔티티+테스트·4개 VM 주입·App 배선이
  걸리는 횡단 변경이라 출시(9/8경) 직전 리스크 대비 이득이 작다.
- **⚠️ 되살릴 때 함정(설계 논의에서 확정)**: 작품 상세 피드 탭·전체 피드 목록엔 **당겨서 새로고침이 없어
  재진입 전체 재조회가 유일한 최신화 수단**이다 — 이 화면들을 셀 동기화로 전환하면 다른 유저의 새 글·변경이
  화면을 새로 push하기 전까지 영영 안 들어온다(전환하려면 pull-to-refresh 추가가 선행). 그래서 소비자는
  피드 탭만으로 결론냈었다. 작성 완료는 FeedID가 없어(생성 API가 id를 안 돌려줌) `created` 무ID 이벤트로
  넣고 목록 전체 재로드로 처리해야 한다.

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

### 4. A4 Swift 6 — 잔여 concurrency 경고 3건 ✅완료(#221) / Feature @MainActor 완주 대기

- **경고 3건 = 해결(#221, 2026-08-29)**: 남아 있던 3건은 전부 `NovelDetailFeature`의 `TopBounceDisabler`
  (`UIScrollView.observe(\.contentOffset)` KVO)였다. #219에서 `MainActor.assumeIsolated` 래핑은 **경고는
  없애지만 상단 클램프가 실기기에서 깨져** 되돌렸었다. #221에서 **KVO 클램프를 아예 걷어내고 #200 컬렉션
  상세식 순수 SwiftUI stretch 헤더로 교체**했다(당겨서 내리면 배경을 그만큼 확대해 빈 영역을 메움) → KVO
  소멸 → `enableSwift6: true`로 승격. 실기 대신 시뮬레이터 stretch probe(고정 stretch 값 주입)로 채움·경계
  고정을 실측하고, 스크롤/스티키 탭/네비 타이틀 무회귀 확인.
  - **덤(mode 6가 드러낸 추가 결함)**: 승격 시 `NovelNotificationSettingSheetViewModel`에서 data-race error가
    떴다 — `NovelNotificationSetting`(NotificationDomain Entity)만 `Sendable`이 빠져 있었다(형제 엔티티는 전부
    Sendable). 값 타입이라 `Sendable` 추가로 해결. 이슈가 "KVO가 유일한 잔여"라 한 것은 #189(알림 시트)가
    그 뒤 들어와 stale했던 것.
- **남은 것 — Feature @MainActor 완주(선택)**: #219는 UseCase/Entity를 Sendable로 만들어 Feature "sending"
  경고를 cascade로 없앴다(@MainActor 없이). Feature를 mode 6으로 올린 지금, VM에 `@MainActor`를 명시하는 게
  정석이므로 12개 Feature VM에 @MainActor를 붙이고 화면별로 검증하는 일이 남는다(로드맵 3단계 본래 취지).

### 5. A4 Swift 6 — 경고 0 레이어·Feature mode 6 승격 ✅완료 / App·Demo·Tests 대기 (5·6단계)

- **완료(5단계)**: 경고 0을 달성한 **Core·Domain·Data·UI 32개 모듈**의 Sources 타깃을 **Swift 6 language
  mode**(`SWIFT_VERSION = 6`)로 승격했다 — concurrency 위반이 이제 warning이 아니라 **컴파일 error**다
  (로컬 Xcode·CI 모두 자동으로 막음). 32모듈 전부 mode 6에서 error 0으로 빌드됨을 실측 확인(fresh DD 모듈 스킴 순회).
  - **구현**: `Tuist/ProjectDescriptionHelpers/Project+Templates.swift`의 `swift6SourcesSettings`를
    `makeBaseTargets`의 **Sources 타깃에만** 주입(Core·Domain·Data·UI create 함수에서 전달, Feature는 미전달).
    `env.baseSetting`(전역)이 아닌 이유: #219는 Sources만 청소했고 Demo/Testing/Tests는 strict concurrency
    미청소라, 전역/프로젝트 세팅에 얹으면 그쪽이 error로 깨진다. Sources 타깃 한정으로 회피.
  - **왜 scan.sh --strict CI가 아니라 pbxproj 직접 승격인가**: 컴파일러 error가 report-only CI 게이트보다
    강하고 빠르다(로컬 빌드에서 즉시, 전 모듈 재컴파일하는 무거운 CI job 불필요). 승격된 레이어만큼 그
    존재 이유가 사라져 → **44모듈 승격 후 `Tooling/StrictConcurrency/`와 `strict-concurrency` CI job을 제거함**(아래).
- **6단계 진행 — Feature 12개 전부 승격 완료**: `createFeatureModule`에 `enableSwift6: Bool = true` 파라미터를
  추가해 Feature Sources를 mode 6으로 올렸다. 처음엔 NovelDetailFeature만 KVO 미해결로 `false`였으나 **#221에서
  TopBounceDisabler를 stretch 헤더로 교체하며 승격**(위 4번). 검증: 전부 **BUILD SUCCEEDED·Sources error 0**
  실측(fresh DD) + NovelDetail·Home·Library·Search Demo 시뮬레이터 스모크 정상.
- **남은 것**: ① **App(WSS-iOS)**(Feature 전부가 mode 6이 된 지금 마지막 승격 대상) ② **각 모듈 Demo/Testing/Tests**
  (별건 — 예: Demo Mock UseCase의 `store`가 non-Sendable이라 mode 6 오버라이드 시 error. Sources 승격엔 무관하나
  Demo까지 올리려면 정리 필요).
- **정리 완료(6단계와 함께)**: `Tooling/StrictConcurrency/scan.sh`·`README.md`와 `test.yml`의
  `strict-concurrency`(Swift 6 Readiness) job·주간 `schedule` cron을 **제거함**. 근거: 44모듈이 mode 6라
  컴파일러가 회귀를 error로 막고(report-only 스캐너보다 강함), 남은 mode 5(App·Demo/Tests) 승격은
  "그 스킴을 mode 6으로 직접 빌드"가 scan.sh의 `complete`-warning 집계보다 정확하다(warning 0 ≠ mode 6 error 0).
- **Feature @MainActor 완주(선택)**: #219는 UseCase/Entity를 Sendable로 만들어 Feature "sending" 경고를
  cascade로 없앴다(@MainActor 없이). Feature를 mode 6으로 올릴 때 VM을 `@MainActor`로 명시하는 게 정석이므로
  (로드맵 3단계 본래 취지), 그때 12개 Feature VM에 @MainActor를 붙이고 화면별로 검증한다.
