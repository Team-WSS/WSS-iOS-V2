fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_dev_certificates

```sh
[bundle exec] fastlane ios sync_dev_certificates
```

개발용(Development) 인증서·프로비저닝 프로파일을 로컬로 동기화한다

### ios debug_beta

```sh
[bundle exec] fastlane ios debug_beta
```

Debug 스킴 TestFlight 배포

### ios release_beta

```sh
[bundle exec] fastlane ios release_beta
```

Release 스킴 TestFlight 배포

### ios release

```sh
[bundle exec] fastlane ios release
```

Release 스킴 App Store 제출

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
