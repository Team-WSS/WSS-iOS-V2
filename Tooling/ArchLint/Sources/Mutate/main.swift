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
// 원본은 시작할 때 읽어 두고, Ctrl-C나 실행 실패로 끝나도 되돌린다. 그래도 남으면 `git checkout -- <모듈>/Sources`.

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

/// 버그를 심기 전 소스 원본(경로 → 내용). 어떻게 끝나든 이것으로 되돌린다.
nonisolated(unsafe) var originals: [String: String] = [:]
/// 소스 쓰기를 한 번에 하나만 — Ctrl-C로 되돌린 뒤에 다음 버그가 심기지 않게 한다.
let sourceLock = NSLock()

func restoreSources() {
    sourceLock.lock()
    for (path, source) in originals {
        try? source.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

/// 파일로 보내도 버그 하나 끝날 때마다 바로 보이게 버퍼 없이 내보낸다.
func say(_ message: String) {
    FileHandle.standardOutput.write(Data((message + "\n").utf8))
}

func fail(_ message: String) -> Never {
    restoreSources()
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

@discardableResult
func run(
    _ launchPath: String, _ arguments: [String], in directory: String, timeout: TimeInterval? = nil
) -> (status: Int32, output: String, timedOut: Bool) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: directory)
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do { try process.run() } catch { fail("실행 실패: \(launchPath) \(error)") }
    // 무한 루프가 생기는 버그도 있다 — 시간을 넘기면 끊는다.
    let timer = DispatchWorkItem { if process.isRunning { process.terminate() } }
    if let timeout { DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer) }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let timedOut = timeout != nil && !timer.isCancelled && process.terminationReason == .uncaughtSignal
    timer.cancel()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self), timedOut)
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

/// 사용 가능한 iPhone 시뮬레이터 하나(CI와 같은 방식)와 지금 켜져 있는지.
func simulator() -> (id: String, isBooted: Bool) {
    let result = run("/usr/bin/xcrun", ["simctl", "list", "devices", "available", "-j"], in: ".")
    guard let json = try? JSONSerialization.jsonObject(with: Data(result.output.utf8)) as? [String: Any],
          let devices = json["devices"] as? [String: [[String: Any]]] else { fail("시뮬레이터 목록을 읽지 못했다") }
    for runtime in devices.keys.sorted(by: >) where runtime.contains("iOS") {
        for device in devices[runtime] ?? [] {
            if let name = device["name"] as? String, name.contains("iPhone"), let id = device["udid"] as? String {
                return (id, device["state"] as? String == "Booted")
            }
        }
    }
    fail("iPhone 시뮬레이터가 없다")
}

enum Outcome {
    case killed, timedOut, survived, notCompiled
}

let derivedDataPath = FileManager.default.temporaryDirectory.appendingPathComponent("wss-mutation-derived-data").path

func runTests(scheme: String, root: String, simulator: String, timeout: TimeInterval? = nil) -> Outcome {
    let result = run("/usr/bin/xcodebuild", [
        "test",
        "-workspace", "WSS-iOS-V2.xcworkspace",
        "-scheme", scheme,
        "-sdk", "iphonesimulator",
        "-destination", "platform=iOS Simulator,id=\(simulator)",
        // Xcode가 쓰는 DerivedData와 따로 둔다 — 같은 곳을 동시에 빌드하면 build.db가 깨진다.
        // 레포 안(.build)에 두지 않는다 — 레포 안 빌드 폴더가 rebase를 깬 적이 있다.
        "-derivedDataPath", derivedDataPath,
        // 테스트가 실패하면(버그를 잡으면) xcodebuild가 시뮬레이터 진단을 모으느라 몇 분씩 멈춘다. 이 도구엔 필요 없다.
        "-collect-test-diagnostics", "never",
        "-quiet"
    ], in: root, timeout: timeout)
    if result.timedOut { return .timedOut }
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
    originals[file] = source
    mutants += MutantGenerator.mutants(in: source, path: file)
}

func relative(_ path: String) -> String {
    path.replacingOccurrences(of: options.root + "/", with: "")
}

if options.listOnly {
    for mutant in mutants { say("\(relative(mutant.path)):\(mutant.line) \(mutant.summary)") }
    say("심을 버그 \(mutants.count)개")
    exit(0)
}

let status = run("/usr/bin/git", ["status", "--porcelain", "--", moduleDir + "/Sources"], in: options.root)
guard status.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    fail("\(relative(moduleDir))/Sources에 커밋 안 한 변경이 있다 — 소스를 고쳤다 되돌리는 도구라 먼저 정리한다")
}

// 꺼진 시뮬레이터를 넘기면 xcodebuild가 실행마다 켰다 끈다(한 번에 30초 넘게 든다). 미리 켜 두고, 도구가 켰으면 끝날 때 끈다.
let (simulatorID, wasBooted) = simulator()
if !wasBooted {
    run("/usr/bin/xcrun", ["simctl", "boot", simulatorID], in: ".")
    run("/usr/bin/xcrun", ["simctl", "bootstatus", simulatorID], in: ".")
}
func restoreSimulator() {
    if !wasBooted { run("/usr/bin/xcrun", ["simctl", "shutdown", simulatorID], in: ".") }
}
// Ctrl-C로 끊어도 심은 버그를 남기지 않는다.
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .global())
let shutdownSimulatorOnInterrupt = !wasBooted
let interruptedSimulatorID = simulatorID
interrupt.setEventHandler { @Sendable in
    restoreSources() // 잠금을 풀지 않고 끝낸다 — 그 뒤로는 아무도 소스를 쓰지 못한다.
    if shutdownSimulatorOnInterrupt {
        run("/usr/bin/xcrun", ["simctl", "shutdown", interruptedSimulatorID], in: ".")
    }
    FileHandle.standardError.write(Data("\n중단 — 소스를 되돌렸다\n".utf8))
    exit(130)
}
interrupt.resume()

say("시작: \(options.module) — 버그 \(mutants.count)개")

guard runTests(scheme: options.module, root: options.root, simulator: simulatorID) == .survived else {
    restoreSimulator()
    fail("버그를 심기 전 테스트부터 실패한다 — 먼저 테스트를 통과시킨다")
}

var survivors: [Mutant] = []
var notCompiled = 0
// 버그 하나에 보통 몇 초다. 이보다 오래 걸리면 버그가 무한 루프를 만든 것으로 본다.
let mutantTimeout: TimeInterval = 300

for (index, mutant) in mutants.enumerated() {
    guard let original = originals[mutant.path] else { continue }
    sourceLock.lock()
    do {
        try mutant.apply(to: original).write(toFile: mutant.path, atomically: true, encoding: .utf8)
    } catch {
        sourceLock.unlock()
        fail("버그를 심지 못했다: \(relative(mutant.path)) \(error)")
    }
    sourceLock.unlock()
    let startedAt = Date()
    let outcome = runTests(scheme: options.module, root: options.root, simulator: simulatorID, timeout: mutantTimeout)
    sourceLock.lock()
    do {
        try original.write(toFile: mutant.path, atomically: true, encoding: .utf8)
    } catch {
        // 되돌리지 못한 채 다음 버그를 심으면 버그가 겹친다 — 여기서 멈춘다.
        sourceLock.unlock()
        fail("소스를 되돌리지 못했다: \(relative(mutant.path)) \(error)")
    }
    sourceLock.unlock()

    let label: String
    switch outcome {
    case .killed: label = "잡힘"
    case .timedOut: label = "잡힘(시간 초과)"
    case .survived: label = "생존"; survivors.append(mutant)
    case .notCompiled: label = "컴파일 안 됨"; notCompiled += 1
    }
    let seconds = Int(Date().timeIntervalSince(startedAt))
    say("[\(index + 1)/\(mutants.count)] \(label) (\(seconds)초) \(relative(mutant.path)):\(mutant.line) \(mutant.summary)")
}

restoreSimulator()

let valid = mutants.count - notCompiled
say("")
say("결과: 버그 \(valid)개 중 \(valid - survivors.count)개를 테스트가 잡았다(컴파일 안 된 \(notCompiled)개 제외)")
if !survivors.isEmpty {
    say("살아남은 버그 — 테스트가 이 동작을 지키지 않는다. 테스트를 더할지, 의미 없는 변이인지 사람이 판단한다:")
    for mutant in survivors { say("  \(relative(mutant.path)):\(mutant.line) \(mutant.summary)") }
}
