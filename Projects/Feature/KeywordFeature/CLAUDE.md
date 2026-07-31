<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# KeywordFeature

키워드 검색 화면. 카테고리별 브라우징(2줄 접기/펼치기) + 검색어 제출 시 평탄화된 결과 + 다중 선택(선택 트레이).

- 식별자: `ModuleType.feature(.keyword)` / 의존: `BaseDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- ⚠️ **별도 `KeywordDomain` 없음** — 키워드 검색 UseCase(`SearchKeywordsUseCase`)·Repository·Entity(`Keyword`, `KeywordGroup`, `KeywordCategory`)는 전부 `BaseDomain/Sources/Keyword/`에 있다. Demo 앱은 실서버 조립을 위해 `BaseData`(`DefaultKeywordRepository`)를 의존한다.

## 핵심 시나리오

- **브라우징**: 진입 시 `LoadTotalKeywordsUseCase`로 전체 카테고리(`KeywordCategory.allCases`)를 로드. 카테고리별 블록은 기본 2줄만 보이고 chevron으로 펼침/접힘.
- **검색**: `WSSSearchBar`의 제출(엔터·버튼)에서만 `SearchKeywordsUseCase`를 호출 — 실시간(타이핑 중) 검색 아님. 결과는 카테고리 구분 없는 평탄한 키워드 칩 리스트, 빈 결과는 화면 중앙 `WSSEmptyView`.
- **취소**: `WSSSearchBar`의 x 버튼(`onCancel`)을 누르면 검색을 취소하고 포커스를 내려 브라우징 화면으로 복귀한다.
- **선택**: 브라우징·검색 결과 어디서든 칩을 탭하면 선택 토글(`state.selectedKeywords`, 선택 순서 유지). 선택된 키워드는 서치바 바로 아래 가로 스크롤 트레이(`WhiteRemovableKeywordChip`)에 표시된다. **트레이 칩은 `onSelect`를 생략해 몸통 탭을 의도적으로 비활성화하고, X 버튼(`onDelete`)만 `.toggleKeyword`로 해제한다**(`onSelect`는 `WhiteRemovableKeywordChip`에서 `(() -> Void)? = nil`) — 브라우징/검색 결과 칩(`CapsuleSelectableKeywordChip`, 몸통 탭=토글)과 인터랙션이 다르니 섞어 가정하지 말 것. 하단 액션바의 "초기화"로 전체 해제.
- **포커스 시 흰 화면**: 서치바가 포커스를 얻으면(`isSearchBarFocused`) 검색 여부와 무관하게 카테고리 브라우징(회색 배경)을 숨기고 흰 배경만 보여준다.

## 주의사항 (작업 중 발견 시 누적)

- **화면 모드(브라우징/검색결과/포커스 흰화면) 전환은 `keywordText`가 아니라 VM의 `state.query`(제출된 검색어) + View의 `isSearchBarFocused` 조합 기준**이다. `keywordText`(입력 중인 글자)로 판단하면 제출 전 타이핑 중에도 "검색 결과가 없어요" 빈 화면이 먼저 깜빡인다. `state.query`는 오직 `.search` 액션(제출·취소 시)에만 갱신된다.
- **`SearchKeywordsUseCase.execute` 응답에 stale 가드가 걸려 있다** — 응답 도착 시점에 `state.query`가 요청 당시와 다르면(그사이 새 검색을 제출) 결과를 버린다. 반면 `LoadTotalKeywordsUseCase`(브라우징 로드)에는 있는 캐시 미스 재시도 폴백이 `SearchKeywordsUseCase`엔 없다 — `.load`가 먼저 캐시를 채워주는 정상 흐름에선 문제없지만, 검색이 로드보다 먼저 실행되는 경로가 생기면 재시도 없이 실패한다.
- **카테고리 블록의 접힘(2줄)은 `WSSFlowLayout`에 줄 제한 기능을 넣지 않고, 고정 높이(80 = 칩35+간격8+칩35+여유2) + `.clipped()`로 구현**했다. 처음엔 `WSSFlowLayout`에 `maxRows`를 추가해 넘치는 subview를 `place()` 안 부르는 방식으로 숨기려 했으나, **SwiftUI가 place 안 된 subview를 화면 한가운데 근처에 겹쳐서 그려버리는 버그**를 실제로 겪었다(플레이스홀더 텍스트가 뒤엉켜 보임). 칩 높이가 고정값이라 높이 클램프로 충분해 그 방식은 폐기 — 되살리지 말 것.
- ⚠️ **접힌 카테고리 블록의 `.clipped()`는 그리기만 자르고 히트테스트는 안 자른다** — `WSSFlowLayout`이 `.frame(height:)`로 제안한 높이를 무시하고 항상 전체 줄 수 기준의 본래 크기로 자식을 배치하기 때문에, 안 보이는 나머지 줄 칩들이 실제로는 구분선·확장 버튼 자리까지 배치돼 있다. 그 칩들이 여전히 히트테스트에 반응해 **확장 버튼 탭이 간헐적으로 씹히는** 버그가 있었다(키워드 많은 카테고리일수록 잦음) — `.clipped()` 뒤에 `.contentShape(Rectangle())`를 붙여 히트 영역을 보이는 프레임으로 재지정해 해결. `scaledToFill().clipShape()` 트랩(WSSComponent CLAUDE.md, #154)과 트리거는 다르지만 "시각적 클리핑≠히트테스트 클리핑"이라는 같은 성질에서 비롯됨.
- **하단 액션바(초기화/N개 선택)는 `.safeAreaInset(edge: .bottom)`로 붙인다** — 예전에 `ZStack(alignment: .bottom)` + 스크롤 콘텐츠에 수동 `.padding(.bottom, 고정값)`으로 자리를 만들었더니, 바의 실제 높이(패딩·세이프에어리어 포함)와 어긋나 마지막 카테고리가 가려졌다. `safeAreaInset`은 바의 실제 크기만큼 자동으로 공간을 예약해 매직넘버가 필요 없다.
- **화면 전체에 `.ignoresSafeArea(.keyboard, edges: .bottom)`가 걸려 있다** — 서치바가 화면 맨 위라 키보드에 가려질 일이 없는데, 이게 없으면 키보드가 뜰 때 SwiftUI 기본 키보드 회피로 하단 액션바까지 키보드를 따라 올라온다. 의도는 액션바가 물리적 하단에 고정된 채 키보드에 덮이는 것.
- **선택 트레이는 새 키워드가 끝(오른쪽)에 추가될 때만 자동 스크롤한다**(`onChange(of: selectedKeywords.count)`, 개수가 늘 때만 — 삭제 시엔 스크롤 안 함). 새 항목을 맨 앞(왼쪽)에 넣는 방식은 일부러 안 씀 — 그러면 기존 칩들이 매번 오른쪽으로 밀리며 위치가 바뀌어 더 산만하다.
- **`CapsuleSelectableKeywordChip`/`WhiteRemovableKeywordChip`은 `Button`이 아니라 `.onTapGesture`라 `snapshot_ui`(UI 자동화) 접근성 트리에 안 잡힌다** — 시뮬레이터 자동 탭 검증이 필요하면 스크린샷으로 좌표를 가늠해 탭해야 한다.
- **검색 결과가 비어있을 때(`WSSEmptyView(type: .keyword)`)의 "키워드 문의하러 가기" 버튼 action이 비어있다(TODO)** — `openURL`로 열어야 할 문의 URL이 정리된 enum이 아직 develop에 병합 안 된 별도 브랜치에 있어서다. 그 브랜치가 머지되면 `SearchKeywordView`의 `openURL` 프로퍼티(이미 선언해둠)를 이용해 action을 채울 것.
