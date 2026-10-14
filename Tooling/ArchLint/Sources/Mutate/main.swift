import Foundation
import MutationCore

// 뮤테이션 도구(#293) — 모듈 소스에 버그를 하나씩 심고 그 모듈 테스트를 돌려, 테스트가 못 잡은(살아남은) 버그를 보고한다.
// 살아남은 버그 = 테스트가 지키지 못하는 동작. 사람이 보고 "테스트를 더한다 / 의미 없는 변이다"를 판단한다.
//
// 사용법(레포 루트에서, tuist generate 후):
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain           # 전체 실행
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain --list    # 심을 버그 목록만
//
// 소스 파일을 직접 고쳤다가 되돌리므로, 모듈 Sources에 커밋 안 한 변경이 있으면 시작하지 않는다.
// 도중에 끊기면 `git checkout -- <모듈>/Sources`로 되돌린다.

struct Options {
    var module = ""
    var root = "."
    var listOnly = false
}

func parseOptions() -> Options {
    var options = Options()
    var arguments = CommandLine.arguments.dropFirst().makeIterator()
    while let argument = arguments.next() {
        switch argument {
        case "--list": options.listOnly = true
        case "--root": options.root = arguments.next() ?? "."
        default: options.module = argument
        }
    }
    return options
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

@discardableResult
func run(_ launchPath: String, _ arguments: [String], in directory: String) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: directory)
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do { try process.run() } catch { fail("실행 실패: \(launchPath) \(error)") }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self))
}

/// `Projects/<레이어>/<모듈>` 경로.
func moduleDirectory(_ module: String, root: String) -> String {
    let projects = root + "/Projects"
    let layers = (try? FileManager.default.contentsOfDirectory(atPath: projects)) ?? []
    for layer in layers {
        let candidate = "\(projects)/\(layer)/\(module)"
        if FileManager.default.fileExists(atPath: candidate + "/Project.swift") { return candidate }
    }
    fail("모듈을 찾지 못했다: \(module)")
}

func swiftFiles(under directory: String) -> [String] {
    let enumerator = FileManager.default.enumerator(atPath: directory)
    var files: [String] = []
    while let relative = enumerator?.nextObject() as? String {
        if relative.hasSuffix(".swift") { files.append(directory + "/" + relative) }
    }
    return files.sorted()
}

/// 사용 가능한 iPhone 시뮬레이터 하나(CI와 같은 방식).
func simulatorID() -> String {
    let result = run("/usr/bin/xcrun", ["simctl", "list", "devices", "available", "-j"], in: ".")
    guard let json = try? JSONSerialization.jsonObject(with: Data(result.output.utf8)) as? [String: Any],
          let devices = json["devices"] as? [String: [[String: Any]]] else { fail("시뮬레이터 목록을 읽지 못했다") }
    for runtime in devices.keys.sorted(by: >) where runtime.contains("iOS") {
        for device in devices[runtime] ?? [] {
            if let name = device["name"] as? String, name.contains("iPhone"), let id = device["udid"] as? String {
                return id
            }
        }
    }
    fail("iPhone 시뮬레이터가 없다")
}

enum Outcome {
    case killed, survived, notCompiled
}

let derivedDataPath = FileManager.default.temporaryDirectory.appendingPathComponent("wss-mutation-derived-data").path

func runTests(scheme: String, root: String, simulator: String) -> Outcome {
    let result = run("/usr/bin/xcodebuild", [
        "test",
        "-workspace", "WSS-iOS-V2.xcworkspace",
        "-scheme", scheme,
        "-sdk", "iphonesimulator",
        "-destination", "platform=iOS Simulator,id=\(simulator)",
        // Xcode가 쓰는 DerivedData와 따로 둔다 — 같은 곳을 동시에 빌드하면 build.db가 깨진다.
        // 레포 안(.build)에 두지 않는다 — 레포 안 빌드 폴더가 rebase를 깬 적이 있다.
        "-derivedDataPath", derivedDataPath,
        "-quiet"
    ], in: root)
    if result.status == 0 { return .survived }
    let compileError = result.output.range(of: #"\.swift:\d+:\d+: error:"#, options: .regularExpression) != nil
    return compileError ? .notCompiled : .killed
}

// MARK: - 실행

let options = parseOptions()
guard !options.module.isEmpty else { fail("사용법: Mutate <모듈 이름> [--list] [--root 레포루트]") }

let moduleDir = moduleDirectory(options.module, root: options.root)
let sourceFiles = swiftFiles(under: moduleDir + "/Sources")
var mutants: [Mutant] = []
for file in sourceFiles {
    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
    mutants += MutantGenerator.mutants(in: source, path: file)
}

func relative(_ path: String) -> String {
    path.replacingOccurrences(of: options.root + "/", with: "")
}

if options.listOnly {
    for mutant in mutants { print("\(relative(mutant.path)):\(mutant.line) \(mutant.summary)") }
    print("심을 버그 \(mutants.count)개")
    exit(0)
}

let status = run("/usr/bin/git", ["status", "--porcelain", "--", moduleDir + "/Sources"], in: options.root)
guard status.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    fail("\(relative(moduleDir))/Sources에 커밋 안 한 변경이 있다 — 소스를 고쳤다 되돌리는 도구라 먼저 정리한다")
}

let simulator = simulatorID()
print("시작: \(options.module) — 버그 \(mutants.count)개. 끊기면 `git checkout -- \(relative(moduleDir))/Sources`로 되돌린다.")

guard runTests(scheme: options.module, root: options.root, simulator: simulator) == .survived else {
    fail("버그를 심기 전 테스트부터 실패한다 — 먼저 테스트를 통과시킨다")
}

var survivors: [Mutant] = []
var notCompiled = 0
for (index, mutant) in mutants.enumerated() {
    guard let original = try? String(contentsOfFile: mutant.path, encoding: .utf8) else { continue }
    try? mutant.apply(to: original).write(toFile: mutant.path, atomically: true, encoding: .utf8)
    let outcome = runTests(scheme: options.module, root: options.root, simulator: simulator)
    try? original.write(toFile: mutant.path, atomically: true, encoding: .utf8)

    let label: String
    switch outcome {
    case .killed: label = "잡힘"
    case .survived: label = "생존"; survivors.append(mutant)
    case .notCompiled: label = "컴파일 안 됨"; notCompiled += 1
    }
    print("[\(index + 1)/\(mutants.count)] \(label) \(relative(mutant.path)):\(mutant.line) \(mutant.summary)")
}

let valid = mutants.count - notCompiled
print("")
print("결과: 버그 \(valid)개 중 \(valid - survivors.count)개를 테스트가 잡았다(컴파일 안 된 \(notCompiled)개 제외)")
if !survivors.isEmpty {
    print("살아남은 버그 — 테스트가 이 동작을 지키지 않는다. 테스트를 더할지, 의미 없는 변이인지 사람이 판단한다:")
    for mutant in survivors { print("  \(relative(mutant.path)):\(mutant.line) \(mutant.summary)") }
}
