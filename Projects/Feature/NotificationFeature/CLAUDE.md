<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationFeature

알림 목록·알림 상세 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.notification)` / 의존: `BaseDomain`, `NotificationDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점(둘 다 `NotificationFactory` — 대등한 화면이라 양쪽 다 `makeXxxView`):
  - `makeNotificationListView(loadPagedNotificationsUseCase:markNotificationAsReadUseCase:logger:onNotificationSelected:onFeedSelected:onAuthenticationRequired:)` — 홈 알림 벨에서 **push**
  - `makeNotificationDetailView(notificationID:loadNotificationDetailUseCase:logger:onAuthenticationRequired:)` — 목록에서 **push**
- **모듈 안에 `navigationDestination`은 없다** — 목록 → 상세 전환도 콜백으로 올리고 배선은 호출자(App/Demo)가 한다.

## 핵심 시나리오

- **목록 로드**: 진입 1회(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤. 커서는 서버 발급 문자열이 아니라
  **마지막으로 받은 `NotificationID`**(`lastNotificationID`)이고, 종료 판단은 응답의 `isLoadable`이다.
- **셀 탭 = 두 가지 일**: ① VM이 읽음 처리(낙관 반영 + `MarkNotificationAsReadUseCase`), ② View가
  `NotificationDeeplink`를 분기해 상위 콜백 발화(`.notificationDetail`→상세, `.feedDetail`→피드, `.unknown`/nil→전환 없음).
- **에러 분화**: 첫 페이지 실패=전면 `NetworkErrorView`(재시도), 더보기 실패=토스트, 인증 만료=`requiresAuthentication`
  신호 → `onAuthenticationRequired` 콜백(Feature 공통 계약).

## 화면 동작 계약 (#181)

정적 디자인으로는 안 잡혀 **확인받아 확정한 것**만 적는다(정본·컨벤션으로 정해지는 건 제외).

- **시안 2장은 별개 화면**이다(노드명이 둘 다 "알림"이라 헷갈리기 쉽다) — 목록과 상세는 상단 "고정 영역"
  (뒤로가기 + 중앙 "알림" `title2`)만 공유하고 그 아래가 완전히 다르다.
- **읽음/미읽음은 셀 배경색으로만 구분**한다 — 미읽음 `wssPrimary20`, 읽음 `wssWhite`. 뱃지·점 표시는 없다.
  - ⚠️ **구분선(`wssGray50` #F4F5F8)은 미읽음 배경(#F5F7FF) 위에서 거의 보이지 않는다.** 두 값 모두 시안
    그대로라 의도된 결과이고, 시안엔 미읽음이 연속으로 오는 배치가 없어 드러나지 않았을 뿐이다.
    **실서버에서는 미읽음이 연달아 오는 게 기본이라 셀 경계가 실제로 사라진다**(#181 실측 — 안 읽은 알림이
    쌓인 계정에선 목록이 한 덩어리로 보인다). 값을 임의로 진하게 바꾸지 말고, 고칠 거면 디자이너와 정할 것.
- **제목은 1줄 말줄임, 본문은 최대 2줄**(시안 근거: 제목 프레임 높이 22 고정 + 말줄임 샘플, 본문 최대 34=2줄).
- **셀 탭은 두 가지를 동시에** 한다 — 읽음 처리(낙관) + 딥링크 전환. **`.unknown`이어도 읽음 처리는 한다**
  (전환만 없음). 갈 곳이 없다고 탭을 죽이면 미읽음 표시를 지울 방법이 사라진다.
- **읽음 처리가 실패해도 롤백하지 않는다** — 화면은 읽음인 채로 두고 로그만 남긴다. 셀 탭은 대개 화면 전환과
  동시에 일어나 사용자가 이미 다음 화면에 있고, 되돌리면 돌아왔을 때 이유 없이 미읽음으로 복귀한 것처럼 보인다.
  읽음 여부는 재진입 시 서버 값으로 다시 맞춰진다. (NovelDetail 관심 토글의 "실패 시 롤백"과 **일부러 다르다**.)
- **빈 상태는 이미지 + 문구뿐, CTA 없음**("아직 도착한 알림이 없어요"). 시안이 없어 확인받아 정했다 —
  알림은 사용자가 직접 만들 수 있는 게 아니라 유도할 행동이 마땅치 않다. 그래서 `WSSEmptyView`(버튼 필수)를
  쓰지 않고 화면이 직접 그린다(`LibraryFeature`의 `noMatchSection`과 같은 판단).
- **아이콘은 서버 이미지**(`NotificationItem.iconURL`)다 — 알림 종류별 로컬 에셋은 DesignSystem에 없다
  (`icAnnouncement`는 홈 알림 벨용). 배경 캡슐(36 / radius 12 / `wssPrimary20`)만 로컬로 그리고 그 안에
  이미지를 27로 얹는다(시안 인셋 4.5).
  - **서버 이미지는 배경 없는 글리프만 온다**(실서버 실측 — #181). 그래서 **배경 캡슐은 반드시 로컬로 그려야**
    하고, 이미지를 배경과 같은 36으로 키우면 캡슐이 가려져 사라진다. 27을 임의로 키우지 말 것.
- **작품 알림(완결·휴재 복귀)은 현재 갈 곳이 없다** — `.novelDetail` 분기와 `onNovelSelected` 콜백은
  **미리 열어뒀지만 서버가 `novelId`를 주지 않아 발화하지 않는다**(매퍼가 `.unknown`으로 떨군다).
  Demo의 "완결 알림" 셀만 `.novelDetail`을 넣어 보강 후의 경로를 미리 확인한다. → [NotificationDomain](../../Domain/NotificationDomain/CLAUDE.md)

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`NotificationID`와 `FeedID`는 둘 다 `IDWrapper<Int>`의 typealias라 컴파일러에겐 같은 타입이다** —
  딥링크 두 갈래를 라우팅할 때 `navigationDestination(for: NotificationID.self)`와 `FeedID.self`를 나란히 두면
  **먼저 등록된 쪽이 양쪽을 다 삼킨다**. 호출자는 반드시 자체 Route enum으로 감싸야 한다(Demo가 `DemoRoute`로 그렇게 한다).
- **읽음 처리는 실패해도 롤백하지 않는다** — 같은 셀 재탭은 `markedAsReadIDs`로 막고 로그만 남긴다.
  읽음 여부는 재진입 시 서버 값으로 다시 맞춰지므로, 실패를 토스트로 알리면 화면 전환과 겹쳐 시끄럽다.
- **`NotificationItem`은 전 프로퍼티가 `let`** — 낙관 반영은 `mutating` 정책이 아니라 새 인스턴스 교체로 한다
  (Domain에 `markedAsRead()` 같은 정책 메서드가 없다).
