// swift-tools-version: 6.0
import PackageDescription

// WSS 아키텍처 검사기(A2). 앱에 링크되지 않는 개발 도구 — swift-syntax로 소스를
// AST 파싱해 리뷰어 눈이 새는 규칙을 CI에서 강제한다(주석·문자열 오탐 없음).
// swift-syntax는 Swift.org 공식 프로젝트라 "외부 의존성 없음" 원칙(앱 런타임)과 무관.
let package = Package(
    name: "ArchLint",
    platforms: [.macOS(.v13)],
    dependencies: [
        // 툴체인 6.3에 정합하는 603.x 라인에 핀(major=603 == Swift 6.3).
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ArchLint",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        )
    ]
)
