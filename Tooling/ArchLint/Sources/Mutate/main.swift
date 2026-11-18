import Foundation
import MutationCore

// 뮤테이션 도구(#293) — 모듈 소스에 버그를 하나씩 심고 그 모듈 테스트를 돌려, 테스트가 못 잡은(살아남은) 버그를 보고한다.
// 살아남은 버그 = 테스트가 지키지 못하는 동작. 사람이 보고 "테스트를 더한다 / 의미 없는 변이다"를 판단한다.
//
// 사용법(레포 루트에서, tuist generate 후):
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain           # 전체 실행
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain --list    # 심을 버그 목록만
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain --changed-since          # origin/develop 이후 바뀐 소스에만
//   swift run --package-path Tooling/ArchLint Mutate AuthDomain --changed-since=HEAD~3   # 다른 기준(`=`로 붙여 쓴다)
// `--changed-since`는 모듈의 테스트(`Tests/`)나 가짜 객체(`Testing/`)가 바뀌었으면 모듈 전체에 심는다 —
// 테스트가 약해지면 손대지 않은 소스의 버그도 새로 살아남기 때문이다.
//
// 소스 파일을 직접 고쳤다가 되돌리므로, 모듈 Sources에 커밋 안 한 변경이 있으면 시작하지 않는다.
// 원본은 시작할 때 읽어 두고, Ctrl-C나 실행 실패로 끝나도 되돌린다. 그래도 남으면 `git checkout -- <모듈>/Sources`.

struct Options {
    var module = ""
    var root = "."
    var listOnly = false
    /// `--changed-since`의 기준 ref. nil이면 모듈 전체.
    var changedSince: String?
}

func parseOptions() -> Options {
    var options = Options()
    var arguments = CommandLine.arguments.dropFirst().makeIterator()
    while let argument = arguments.next() {
        switch argument {
        case "--list": options.listOnly = true
        case "--root": options.root = arguments.next() ?? "."
        case "--changed-since": options.changedSince = "origin/develop"
        case let flag where flag.hasPrefix("--changed-since="):
            let ref = String(flag.dropFirst("--changed-since=".count))
            guard !ref.isEmpty else { fail("--changed-since= 뒤에 기준을 적는다(예: --changed-since=HEAD~3)") }
            options.changedSince = ref
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
        do {
            try source.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            // 되돌리지 못한 파일은 숨기지 않고 알린다 — 버그가 심긴 채 남아 있다.
            FileHandle.standardError.write(Data("되돌리지 못했다: \(path) \(error) — `git checkout -- \(path)`\n".utf8))
        }
    }
}

/// 지금 돌고 있는 자식 프로세스(xcodebuild 등). 신호로 끝낼 때 고아로 남기지 않게 먼저 멈추고,
/// 시간 초과로 멈췄는지도 여기서 기록한다(다른 신호로 죽은 것과 가르기 위해).
final class ChildProcess: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var timedOut = false
    private var stopped = false

    func start(_ newProcess: Process) {
        lock.lock(); defer { lock.unlock() }
        // 신호로 멈추기로 한 뒤에 뜬 프로세스도 바로 멈춘다(고아 방지).
        if stopped { newProcess.terminate() }
        process = newProcess
        timedOut = false
    }

    /// 끝난 프로세스를 내려놓고, 시간 초과로 멈췄는지 돌려준다.
    func finish() -> Bool {
        lock.lock(); defer { lock.unlock() }
        process = nil
        return timedOut
    }

    func timeOut(_ target: Process) {
        lock.lock(); defer { lock.unlock() }
        guard process === target, target.isRunning else { return }
        timedOut = true
        target.terminate()
    }

    func terminate() {
        lock.lock(); defer { lock.unlock() }
        stopped = true
        process?.terminate()
    }
}

let child = ChildProcess()

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
    child.start(process)
    // 무한 루프가 생기는 버그도 있다 — 시간을 넘기면 끊는다.
    let timer = DispatchWorkItem { child.timeOut(process) }
    if let timeout { DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer) }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    timer.cancel()
    let timedOut = child.finish()
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
    if result.status == 0 { return .survived }
    if result.timedOut { return .timedOut }
    let compileError = result.output.range(of: #"\.swift:\d+:\d+: error:"#, options: .regularExpression) != nil
    return compileError ? .notCompiled : .killed
}

// MARK: - 실행

let options = parseOptions()
guard !options.module.isEmpty else {
    fail("사용법: Mutate <모듈 이름> [--list] [--changed-since[=기준, 기본 origin/develop]] [--root 레포루트]")
}

func relative(_ path: String) -> String {
    path.replacingOccurrences(of: options.root + "/", with: "")
}

let moduleDir = moduleDirectory(options.module, root: options.root)
var sourceFiles = swiftFiles(under: moduleDir + "/Sources")

/// 기준 ref와 갈라진 지점 이후 바뀐 파일(레포 루트 기준 상대 경로).
/// 작업 폴더까지 비교하고 추적 안 된 새 파일도 넣는다 — 커밋 전 테스트 수정도 범위에 반영되게.
func changedPaths(since ref: String) -> [String] {
    // 한글 등 ASCII 밖 경로를 따옴표로 감싸지 않게 한다(그러면 소스 경로와 안 맞는다).
    let git = ["-c", "core.quotePath=false"]
    let base = run("/usr/bin/git", git + ["merge-base", ref, "HEAD"], in: options.root)
    let mergeBase = base.output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard base.status == 0, !mergeBase.isEmpty else {
        fail("기준 \(ref)과 갈라진 지점을 찾지 못했다(git merge-base \(ref) HEAD): \(base.output.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    let diff = run("/usr/bin/git", git + ["diff", "--name-only", "--relative", mergeBase], in: options.root)
    guard diff.status == 0 else { fail("git diff 실패: \(diff.output)") }
    let untracked = run("/usr/bin/git", git + ["ls-files", "--others", "--exclude-standard"], in: options.root)
    guard untracked.status == 0 else { fail("git ls-files 실패: \(untracked.output)") }
    return ChangedScope.paths(fromGitOutput: diff.output) + ChangedScope.paths(fromGitOutput: untracked.output)
}

if let ref = options.changedSince {
    // decide는 레포 루트 기준 상대 경로로 비교한다 — 실제 경로(`./Projects/…`)와 오가는 표를 둔다.
    let actualPath = Dictionary(uniqueKeysWithValues: sourceFiles.map { (relative($0), $0) })
    let decision = ChangedScope.decide(
        sourceFiles: sourceFiles.map(relative),
        changedPaths: changedPaths(since: ref),
        moduleDirectory: relative(moduleDir)
    )
    switch decision {
    case .wholeModule:
        say("\(ref) 이후 테스트나 가짜 객체가 바뀌어 모듈 전체에 심는다")
    case .onlyChanged(let files) where files.isEmpty:
        say("\(ref) 이후 바뀐 소스가 없어 심을 버그가 없다")
        exit(0)
    case .onlyChanged(let files):
        sourceFiles = files.compactMap { actualPath[$0] }
        say("\(ref) 이후 바뀐 소스 \(files.count)개에만 심는다:")
        for file in files { say("  \(file)") }
    }
}

var mutants: [Mutant] = []
for file in sourceFiles {
    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
    originals[file] = source
    mutants += MutantGenerator.mutants(in: source, path: file)
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

// 테스트가 없으면 아래 시작 확인이 "테스트부터 실패한다"로 끝나 원인이 가려진다. 판단 코드가 없어 테스트를 다 뺀 모듈이 이 경우다.
guard !swiftFiles(under: moduleDir + "/Tests").isEmpty else {
    fail("\(relative(moduleDir))/Tests에 테스트가 없다 — 잡을 테스트가 없어 뮤테이션을 돌릴 수 없다(판단 코드가 없는 모듈이면 건너뛴다)")
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
// Ctrl-C·kill·터미널 닫기로 끊어도 심은 버그를 남기지 않는다.
let shutdownSimulatorOnInterrupt = !wasBooted
let interruptedSimulatorID = simulatorID
let interrupts = [SIGINT, SIGTERM, SIGHUP].map { signalNumber in
    signal(signalNumber, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .global())
    source.setEventHandler { @Sendable in
        child.terminate() // 돌던 xcodebuild를 고아로 남기지 않는다.
        restoreSources() // 잠금을 풀지 않고 끝낸다 — 그 뒤로는 아무도 소스를 쓰지 못한다.
        if shutdownSimulatorOnInterrupt {
            // run()은 실패하면 fail() → restoreSources()로 같은 잠금을 다시 잡아 멈춘다. 여기선 직접 띄운다.
            let shutdown = Process()
            shutdown.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            shutdown.arguments = ["simctl", "shutdown", interruptedSimulatorID]
            if (try? shutdown.run()) != nil { shutdown.waitUntilExit() }
        }
        FileHandle.standardError.write(Data("\n중단 — 소스를 되돌렸다\n".utf8))
        exit(128 + signalNumber)
    }
    source.resume()
    return source
}

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
        restoreSimulator()
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
        restoreSimulator()
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
