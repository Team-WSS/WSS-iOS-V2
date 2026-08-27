# StrictConcurrency — Swift 6 준비도 스캐너 (A4)

`SWIFT_STRICT_CONCURRENCY=complete`로 전 모듈을 빌드해 **Swift 6에서 error가 될 concurrency
경고**를 레이어/모듈별로 집계한다. AI 검증 체계(#205) 축 A의 마지막 기계 게이트 **A4**의 1단계.

## 왜 필요한가

Swift 6로 한 번에 넘어가면 위험하다 — 애플 공식 가이드도 "모듈 하나씩 천천히"를 전제로 한다.
그래서 A4는 Swift 5 모드를 **그대로 두고** strict concurrency 플래그만 얹는다. 그러면 위반이
error가 아니라 **warning**으로 떠서 빌드는 안 깨지고, "앞으로 error가 될 것들"의 목록·규모만 모을 수 있다.
A1(CI)·A2(ArchLint)·A3(swift-format)가 밟은 **"report-only로 켜기 → 쏟아진 위반 청소 → required 승격"**
순서를 그대로 반복한다.

## 사용

```bash
# 전제: 먼저 tuist generate로 WSS-iOS-V2.xcworkspace 생성
Tooling/StrictConcurrency/scan.sh                 # 전 모듈, report-only, 마크다운 리포트
Tooling/StrictConcurrency/scan.sh --layer Domain  # 한 레이어만(레이어별 승격 검증)
Tooling/StrictConcurrency/scan.sh --strict        # 경고>0이면 종료코드 1(전체 게이트 승격 후)
Tooling/StrictConcurrency/scan.sh --out report.md # 리포트를 파일로도(CI가 PR/Summary에 사용)
```

## 설계 결정 (코드만 봐선 모르는 것)

- **왜 App 스킴(WSS-iOS) 한 방이 아니라 모듈 스킴을 하나씩 도나**: App 스킴을 fresh
  `derivedDataPath`로 빌드해도 프레임워크 모듈이 소스에서 재컴파일되지 않아 경고가 하나도 안
  잡힌다(무엇이 no-op을 만드는지는 불명 — Tuist/Xcode 조합의 함정). 반면 각 **모듈 스킴을 직접
  빌드**하면 그 모듈이 소스에서 컴파일돼 경고가 뜬다(실측 확인). 그래서 모든 모듈 스킴을 **공유 DD**에
  순회 빌드한다(의존 모듈은 한 번만 컴파일 → 재사용).
- **왜 `env.baseSetting`에 안 박고 빌드 오버라이드로만 주입하나**: baseSetting에 넣으면 전 개발자의
  로컬 Xcode 빌드에 경고가 홍수처럼 뜬다(잡음). 이 게이트는 CI에서만 돌면 되므로 xcodebuild
  명령줄 오버라이드로만 얹는다.
- **왜 매 PR이 아니라 수동·주간 스케줄인가**: 전 모듈을 소스에서 재컴파일하는 무거운 잡(macos 러너
  ~10분+)이다. 이건 PR 게이트가 아니라 **"준비도 대시보드"** — `.github/workflows/test.yml`의
  `strict-concurrency` 잡이 `workflow_dispatch`·`schedule`(주간)로만 돈다. 레이어별 경고 0을
  달성한 뒤 그 레이어를 실제로 error로 승격(모듈 빌드 세팅)하는 것이 A4 후속 단계.
- **경고 판별**: strict concurrency가 켜져야만 뜨는 진단 키워드(`Sendable`/`sending`/`actor-isolated`/
  `Swift 6 language mode`/`@preconcurrency` 등)로 거른다. 실측상 이 플래그로 새로 뜨는 경고는
  **전부** concurrency 계열이라 필터가 완전하다(비-concurrency 경고 0).
