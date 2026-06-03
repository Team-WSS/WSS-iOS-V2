# Feature 레이어

실제 **기능·화면**을 구현하는 레이어 (UI 포함). Domain UseCase를 호출해 사용자 시나리오를 완성한다.

> 🚧 **현재 계획 단계.** `ModuleType.feature`에 `home`, `feed`가 선언돼 있으나
> 디스크에 `Projects/Feature/` 폴더는 아직 없다. 첫 Feature 모듈을 만들 때 이 문서를 확정한다.

- 모듈 식별자: `ModuleType.feature(.xxx)` → 모듈명 `XxxFeature`
- 디렉토리(예정): `Projects/Feature/<Module>Feature/`
- 비동기/상태: **Combine** (상태 바인딩·이벤트 조합)

## 의존 규칙 (예정)

- ✅ `Domain`(UseCase·Entity), `UI`(컴포넌트·디자인), `BaseDomain`.
- ❌ `Data` 직접 import 금지 — Data 조립은 App(DI)이 담당하고, Feature는 UseCase/Repository 프로토콜만 받는다.
- ❌ 다른 Feature 모듈 직접 의존 지양 (화면 간 이동은 App/조정 계층에서).

## 코드 규칙 (초안 — 첫 구현 시 확정)

- View(SwiftUI) + ViewModel(Combine) 구성.
- ViewModel은 Domain UseCase를 생성자 주입받아 사용한다 (구현체가 아닌 프로토콜).
- Domain Entity → 화면 표시용 모델로 가공하는 책임은 Feature에 둔다.
- `async/await` UseCase 결과를 Combine 상태로 연결하는 패턴을 여기서 표준화한다.

## 주의사항 (작업 중 발견 시 누적)

- 이 문서는 첫 Feature 모듈 구현 시 실제 코드 기준으로 갱신할 것 (현재 내용은 README의 의도 기반 초안).
