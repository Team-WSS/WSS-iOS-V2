#!/bin/bash
# SPM 파생 프로젝트의 낡은 deployment target을 Xcode 지원 범위로 끌어올린다.
#
# 왜: Xcode 26.6+는 iOS deployment target 하한을 15.0으로 올렸는데, Tuist가 합성하는
# SPM 리소스 번들 타깃(Firebase_FirebaseCore 등 15개)은 패키지 매니페스트의 옛 최소값
# (13.1)을 모델 레벨로 복사해 PackageSettings(baseSettings/targetSettings)로 덮을 수 없다
# (tuist/tuist#11163 — Tuist 4.206 기준 미해결, 실측 확인).
# CLI xcodebuild는 통과하지만 Xcode IDE 빌드는 하드 에러를 낸다.
#
# 언제: `tuist generate` 직후 매번. generate가 파생 프로젝트를 다시 쓰므로 재실행 필수.
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET_VERSION="17.0" # 앱 deployment target과 동일 (EnvironmentPlugin ProjectEnvironment.swift)
patched=0

for pbxproj in Tuist/.build/tuist-derived/Projects/*/*.xcodeproj/project.pbxproj; do
    [ -f "$pbxproj" ] || continue
    # 15.0 미만(9.x~14.x)만 패치 — 이미 정상인 값은 건드리지 않는다
    if grep -qE "IPHONEOS_DEPLOYMENT_TARGET = (9|1[0-4])\." "$pbxproj"; then
        sed -i '' -E "s/IPHONEOS_DEPLOYMENT_TARGET = (9|1[0-4])\.[0-9.]+/IPHONEOS_DEPLOYMENT_TARGET = ${TARGET_VERSION}/g" "$pbxproj"
        echo "패치: $(basename "$(dirname "$pbxproj")")"
        patched=$((patched + 1))
    fi
done

if [ "$patched" -eq 0 ]; then
    echo "패치할 파생 프로젝트 없음 (이미 정상이거나 tuist generate 전)"
else
    echo "완료: ${patched}개 프로젝트 패치됨 (→ ${TARGET_VERSION})"
fi
