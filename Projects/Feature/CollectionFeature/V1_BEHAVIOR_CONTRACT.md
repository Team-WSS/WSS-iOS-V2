# CollectionFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — #205 축 C의 C1 산출물(이슈 #222). 운영 중인 V1(`Team-WSS/WSS-iOS`)의 대응 화면
> 동작을 추출해 V2가 유지/개선/삭제했는지 점검하기 위한 재료다. 분류 범례·읽는 법은 파일럿
> [`../LibraryFeature/V1_BEHAVIOR_CONTRACT.md`](../LibraryFeature/V1_BEHAVIOR_CONTRACT.md) 참조.
> V1 스냅샷 기준 커밋: `Team-WSS/WSS-iOS@eefcb9b2`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 |
|---|---|
| `CreateCollection/` (컬렉션 만들기) | **없음 (V2 신규)** |
| `SearchNovel/` (컬렉션에 담을 작품 검색) | **없음 (V2 신규)** |
| `MyLibrarySelect/` (내 서재에서 선택) | **없음 (V2 신규)** |

## 결론: V1 대응 화면 없음 (V2 신규 기능)

V1(`WSSiOS/Source/Presentation/`)에 **컬렉션(Collection) 화면이 존재하지 않는다** — 검색 결과 `collection` 관련 Presentation 폴더·화면이 없다. CollectionFeature는 V2에서 새로 추가된 기능이므로 **추출할 V1 동작 계약이 없다**.

- 따라서 이 화면의 동작은 V1 대조 대상이 아니라 **V2 자체 계약**(→ [`CLAUDE.md`](CLAUDE.md), 있는 경우)이 정본이다.
- 단, 컬렉션의 하위 동작 중 **작품 검색**(`SearchNovel/`)은 `SearchFeature`의, **내 서재에서 선택**(`MyLibrarySelect/`)은 `LibraryFeature`의 V1 동작을 각각 재료로 삼을 수 있다 — 그 부분의 V1 계약은 해당 모듈의 `V1_BEHAVIOR_CONTRACT.md`를 참조한다. (여기서 중복 추출하지 않는다.)

> 이 문서는 "V1에 대응이 없음"을 명시적으로 남겨, 나중에 "왜 컬렉션엔 V1 계약이 없지?"를 다시 조사하지 않게 하기 위한 것이다.
