// swift-tools-version: 6.0
import PackageDescription

// WSS 아키텍처 검사기(A2). 로직은 ArchLintCore(라이브러리)에 두고 ArchLint(실행 파일)는 얇게 —
// 실행 타깃은 테스트가 import 못 하므로, 규칙을 테스트하려면 라이브러리 분리가 표준.
// swift-syntax는 Swift.org 공식이라 "외부 의존성 없음"(앱 런타임) 원칙과 무관한 개발 도구.
let package = Package(
    name: "ArchLint",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0")
    ],
    targets: [
        .target(
            name: "ArchLintCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "ArchLint",
            dependencies: ["ArchLintCore"]
        ),
        .testTarget(
            name: "ArchLintCoreTests",
            dependencies: ["ArchLintCore"]
        ),
        // 뮤테이션 도구(#293) — 소스에 버그를 하나씩 심어 테스트가 잡는지 본다.
        // 넘기기만 하는 UseCase 판정을 ArchLintCore와 공유한다.
        .target(
            name: "MutationCore",
            dependencies: [
                "ArchLintCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "Mutate",
            dependencies: ["MutationCore"]
        ),
        .testTarget(
            name: "MutationCoreTests",
            dependencies: ["MutationCore"]
        )
    ]
)
