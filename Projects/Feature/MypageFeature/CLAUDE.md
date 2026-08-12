<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# MypageFeature

마이페이지 탭 — 프로필 요약(닉네임·소개·프로필 이미지)·서재 통계·컬렉션·장르 뱃지·작품 취향을 보여주고,
프로필 편집(닉네임·소개·프로필 캐릭터·선호장르)으로 진입한다.

- 식별자: `ModuleType.feature(.mypage)` / 의존: `BaseDomain`, `ProfileDomain`, `NovelDomain`(서재 통계 조회만),
  `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `MypageFactory.makeView(...)`(탭 콘텐츠), `.makeEditView(...)`(프로필 편집), `.makeCharacterEditSheet(...)`(캐릭터 선택 시트)

## 핵심 시나리오

- **마이페이지(`MypageView`)**: `onAppear`마다 프로필·장르 뱃지·작품 취향·서재 통계 4개를 병렬 로드
  (`MypageViewModel.loadMypage`). **탭 복귀마다 다시 로드**한다(1회 가드 없음) — 프로필 편집에서 저장하고
  돌아왔을 때 바뀐 값을 반영해야 해서.
- **프로필 편집(`MyPageEditView`)**: 연필 아이콘 → `navigationDestination` → `MypageFactory.makeEditView`.
  저장 성공 시 곧바로 `dismiss()`하고, "저장됨" 토스트는 **복귀할 마이페이지가** `onSaved` 콜백을 받아
  띄운다(이 화면에서 sleep으로 노출 시간을 벌면 닫힘이 부자연스럽게 지연되므로).
- **캐릭터 선택(`MypageCharacterEditSheet`)**: 프로필 편집 화면의 `+` 버튼 → `.sheet(item:)`으로 진입.
  확인 결과(선택 캐릭터 ID)는 `onApply` 콜백으로 부모(`MyPageEditView`)에 위임하고, draft 반영·시트
  dismiss는 부모 책임.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **캐릭터 선택 시트는 반드시 `.sheet(item:)`으로 연다.** 처음엔 `.sheet(isPresented:)` +
  `characterID`/`nickname`을 시트 밖 별도 State로 들고 있었는데, Feature 레이어 공통 함정
  ([상위 CLAUDE.md](../CLAUDE.md) "시트에 진입 파라미터...") 그대로 **세션 첫 오픈에서만** 그 시점의
  값이 굳어 엉뚱한 캐릭터가 선택 상태로 보였다. 진입 파라미터(`characterID`+`nickname`)를
  `CharacterEditSheetContext: Identifiable`로 묶어 `.sheet(item:)`으로 넘기도록 고쳤다 —
  `.sheet(isPresented:)` + 별도 State 조합으로 되돌리지 말 것.
- ⚠️ **마이페이지 재로드는 `MypageViewModel.isInitialLoading`을 통해서만 로딩 뷰를 띄운다.**
  `state.isLoading`을 직접 보면, 탭 복귀마다 다시 로드하는 정책과 만나 이미 그린 화면 위로 전체 화면
  `LoadingView`가 매번 깜빡인다(HomeFeature와 같은 이유·같은 해법 — `hasLoadedContent` 플래그로
  "아직 보여줄 게 없을 때만" 로딩을 씌운다).
- ⚠️ **닉네임(`NicknameDraft.maxLength`=10)·소개글(`ProfileDraft.maxIntroductionLength`=50) `TextField`는
  VM 상태에 직접 물리지 않는다.** `Binding(get:set:)`의 `set`에서 곧바로 clamp하면, `get`이 SwiftUI가
  방금 그 필드에 마지막으로 써준 값과 같아져 "변화 없음"으로 판단되고, **네이티브 텍스트필드는 사용자가
  입력한 초과분을 화면에 그대로 들고 있는다**(카운터는 맞는데 눈에 보이는 글자 수는 안 맞음 — 시뮬레이터
  실측 확인). `MyPageEditView`는 로컬 `@State` 문자열(`nicknameFieldText`/`introductionFieldText`)에
  물린 뒤 `.onChange`에서 "clamp → 다르면 로컬에 재대입(진짜 변경으로 인식돼 네이티브 필드가 강제로
  되돌아감) → 같으면 VM에 전달"의 2단계로 처리한다. 글자수 제한이 있는 새 `TextField`를 만들 때 이
  패턴을 재사용할 것 — 일반 규칙은 [상위 CLAUDE.md](../CLAUDE.md) 주의사항 참고.
