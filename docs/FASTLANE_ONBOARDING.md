# fastlane 실기기 서명 온보딩

신규 팀원이 실기기(Debug 스킴)를 빌드하기까지, 그리고 새 기기를 추가할 때 밟는 절차.
전체 배경(왜 fastlane/match를 쓰는지)은 [docs/TODO.md](TODO.md) 4번 참고.

## 최초 셋업 (신규 팀원)

1. **Apple Developer Program 팀 초대 확인** — Team Agent/Admin에게 요청. App Store Connect →
   사용자 및 액세스 → `+`로 초대, 최소 Developer 역할.
2. **GitHub `Team-WSS/WSS-iOS-Certificates` 저장소(또는 그 org) 접근 권한** — Apple Developer 팀
   초대와 완전히 별개 권한이라 따로 요청해야 한다. SSH 키가 없으면 `Matchfile`의 SSH 주소
   (`git@github.com:...`)로 clone이 실패한다 — SSH 키를 새로 등록하거나 HTTPS로 접근해야 한다.
3. `bundle install`.
4. `fastlane/.env` 생성(레포에 없음, `.gitignore` — 값은 팀 채널/1Password 등 비공개 채널로 전달받는다).
5. `ASC_KEY_PATH`가 가리키는 `.p8` 키 파일 자체도 `fastlane/`에 받아서 넣기(`fastlane/*.p8`도
   `.gitignore`돼 있어 레포엔 없음 — 파일째로 전달받아야 함).
6. 본인 기기 UDID를 Xcode `Window > Devices and Simulators` 또는 Finder에서 확인해
   [Apple Developer 사이트](https://developer.apple.com/account/resources/devices/list)에
   직접 등록(Devices → `+`).
7. `bundle exec fastlane ios sync_dev_certificates` 실행. **첫 실행 시 `MATCH_PASSWORD` 입력
   프롬프트가 뜬다** — 실제 암호(팀 채널로 전달받은 값)를 한 번 입력하면 macOS Keychain에 자동
   저장되어 이후엔 다시 안 물어본다.
8. 기기를 맥에 연결해 신뢰 설정(맥에서 기기 신뢰 + 기기 설정 > 일반 > VPN 및 기기 관리에서 개발자
   앱 신뢰).
9. Xcode(또는 XcodeBuildMCP)로 Debug 스킴 실기기 Run 시도.
   ⚠️ 아직 끝까지 검증된 절차는 아님 — docs/TODO.md 4번의 "아직 실측 못 한 것" 참고, 막히면 그쪽에
   실측 기록을 추가할 것.

## `sync_dev_certificates`가 내부적으로 하는 일

```
① app_store_connect_api_key  — ASC API 키로 인증
② match(force_for_new_devices: true) — Dev Portal에 등록된 기기 목록과 현재 프로파일을 비교해,
                                        빠진 기기가 있으면 프로파일을 재발급해 인증서 저장소(git)에 반영
```

## 새 기기만 추가할 때 (이미 셋업된 팀원)

위 1~5단계(팀 권한·`.env`)는 끝난 상태이므로 아래만 하면 된다.

1. [Apple Developer 사이트](https://developer.apple.com/account/resources/devices/list)에서
   UDID 직접 등록.
2. **아무나 한 명만** `bundle exec fastlane ios sync_dev_certificates` 실행 — `force_for_new_devices`가
   새 기기를 감지해 프로파일을 재발급.
3. 나머지 팀원은 본인 `sync_dev_certificates`를 그냥 다시 실행하면 저장소에서 갱신된 프로파일을
   받아온다. 재발급을 각자 할 필요는 없다.
