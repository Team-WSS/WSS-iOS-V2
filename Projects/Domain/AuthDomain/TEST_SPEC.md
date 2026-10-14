# AuthDomain 테스트 명세

<!-- 자동 생성 파일 — 손으로 고치지 않는다. 갱신: swift run --package-path Tooling/ArchLint ArchLint --write-test-specs . -->

## 탈퇴 사유 작성

`Tests/Entity/WithdrawalReasonDraftTests.swift`

- 처음에는 '자주 사용하지 않아서' 항목이 골라져 있고, 탈퇴 이유는 비어 있고, 정책에 동의하지 않은 상태다
- '직접입력' 항목을 고르면 탈퇴 이유를 작성할 수 있다
- '직접입력'이 아닌 항목에서는 탈퇴 이유를 작성해도 저장되지 않는다
  - `WithdrawalReasonOption.notFrequentlyUsed`
  - `.inconvenientAndBuggy`
  - `.wantToDeleteContent`
  - `.noDesiredContent`
- 탈퇴 이유는 80자까지 그대로 저장된다
- 탈퇴 이유가 80자를 넘으면 앞 80자만 남는다
- '직접입력'에서 다른 항목으로 바꾸면 작성한 탈퇴 이유가 지워진다
  - `WithdrawalReasonOption.notFrequentlyUsed`
  - `.inconvenientAndBuggy`
  - `.wantToDeleteContent`
  - `.noDesiredContent`
- '직접입력'을 다시 골라도 작성한 탈퇴 이유는 그대로다
- 정책에 동의하지 않으면 어떤 항목을 골라도 제출할 수 없다
  - `WithdrawalReasonOption.allCases`
- 정책에 동의하면 '직접입력'이 아닌 항목은 바로 제출할 수 있다
  - `WithdrawalReasonOption.notFrequentlyUsed`
  - `.inconvenientAndBuggy`
  - `.wantToDeleteContent`
  - `.noDesiredContent`
- '직접입력'은 탈퇴 이유를 작성하고 정책에 동의하면 제출할 수 있다
- '직접입력'은 탈퇴 이유가 비었거나 공백뿐이면 정책에 동의해도 제출할 수 없다
  - `""` — 아무것도 쓰지 않음
  - `"   "` — 스페이스만
  - `"\n\t "` — 줄바꿈·탭도 공백으로 본다
- 정책 동의를 취소하면 다시 제출할 수 없다
