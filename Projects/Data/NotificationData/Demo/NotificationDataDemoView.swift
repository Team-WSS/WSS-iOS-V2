//
//  NotificationDataDemoView.swift
//  NotificationDataDemo
//

import SwiftUI

import BaseData
import BaseDomain
import Logger
import Networking
import NotificationData
import NotificationDomain

private func describeError(_ error: RepositoryError) -> String {
    switch error {
    case .networkUnavailable:      return "❌ networkUnavailable\n→ 네트워크 연결 없음 또는 요청 자체가 전송되지 않음"
    case .authenticationRequired:  return "❌ authenticationRequired\n→ 인증 토큰 없음 또는 만료 (HTTP 401)"
    case .serverUnavailable:       return "❌ serverUnavailable\n→ 서버 오류 (HTTP 5xx)"
    case .invalidData:             return "❌ invalidData\n→ 서버 응답 파싱 실패 (JSON 디코딩 오류)"
    case .notFound:                return "❌ notFound\n→ 리소스를 찾을 수 없음 (HTTP 404)"
    case .unknown:                 return "❌ unknown\n→ 매핑되지 않은 오류 (기타 HTTP 오류 또는 예외)"
    }
}

@Observable
final class DemoLogger: Logger {
    var output: String = ""

    func debug(_ message: String) { append(message) }
    func info(_ message: String)  { append(message) }
    func error(_ message: String) { append(message) }

    func log(_ message: String)   { append(message) }
    func clear() { output = "" }

    private func append(_ message: String) {
        output = output.isEmpty ? message : output + "\n" + message
    }
}

private final class LoggingNetworkingClient: NetworkingRequestable {
    private let underlying: NetworkingRequestable
    private let logger: DemoLogger

    init(underlying: NetworkingRequestable, logger: DemoLogger) {
        self.underlying = underlying
        self.logger = logger
    }

    func request(_ endpoint: Endpoint) async throws -> Data {
        logger.log(formatRequest(endpoint))
        return try await underlying.request(endpoint)
    }

    private func formatRequest(_ endpoint: Endpoint) -> String {
        let req = endpoint.urlRequest
        var lines: [String] = []

        lines.append("━━━━━━━━━━━━━━━━━━━━━━")
       

        if let headers = req.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("Headers:")
            for key in headers.keys.sorted() {
                let value = headers[key] ?? ""
                let display = key.lowercased() == "authorization" ? "" : value
                lines.append("  \(key): \(display)")
            }
        }

        if let body = req.httpBody, !body.isEmpty {
            if let pretty = prettyJSON(body) {
                lines.append("Body:")
                lines.append(pretty)
            } else if let raw = String(data: body, encoding: .utf8) {
                lines.append("Body: \(raw)")
            }
        }

        lines.append("━━━━━━━━━━━━━━━━━━━━━━")
        return lines.joined(separator: "\n")
    }

    private func maskToken(_ value: String) -> String {
        let parts = value.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return String(repeating: "*", count: 6) }
        return "\(parts[0]) \(parts[1].prefix(8))..."
    }

    private func prettyJSON(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
              let str = String(data: pretty, encoding: .utf8) else { return nil }
        return str
    }
}

struct NotificationDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var notificationIDText: String = ""
    @State private var lastIDText: String = ""
    @State private var sizeText: String = "20"
    @State private var deviceTokenText: String = ""
    @State private var deviceIDText: String = ""
    @State private var isPushEnabled: Bool = true
    @State private var isLoading: Bool = false

    private let notifRepo: NotificationRepository
    private let pushRepo: PushSettingRepository
    private let demoLogger: DemoLogger

    init() {
        let logger = DemoLogger()
        let loggingClient = LoggingNetworkingClient(
            underlying: NetworkingClient(),
            logger: logger
        )
        let dataLogger = DataLogger(moduleName: "NotificationData", underlying: logger)
        self.demoLogger = logger
        self.notifRepo = NotificationDataFactory.makeNotificationRepository(client: loggingClient, logger: dataLogger)
        self.pushRepo  = NotificationDataFactory.makePushSettingRepository(client: loggingClient, logger: dataLogger)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    notificationSection
                    Divider()
                    pushSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Notification Demo")
        }
    }

    // MARK: - Sections

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notification").font(.headline).padding(.horizontal)

            demoButton("미읽음 상태 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                Task { await loadUnreadStatus() }
            }
            .padding(.horizontal)

            HStack {
                TextField("lastID (optional)", text: $lastIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                TextField("size", text: $sizeText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            .padding(.horizontal)

            demoButton("알림 목록 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                Task { await loadNotifications() }
            }
            .padding(.horizontal)

            HStack {
                TextField("알림 ID", text: $notificationIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                demoButton("상세 조회", bg: Color(red: 0.92, green: 0.90, blue: 0.99), fg: .indigo) {
                    Task { await loadDetail() }
                }
                demoButton("읽음 처리", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                    Task { await markAsRead() }
                }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private var pushSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Push Setting").font(.headline).padding(.horizontal)

            demoButton("푸시 설정 조회", bg: Color(red: 0.92, green: 0.95, blue: 1.0), fg: .blue) {
                Task { await loadPushPreference() }
            }
            .padding(.horizontal)

            HStack {
                Text("푸시 활성화")
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $isPushEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal)

            demoButton("푸시 설정 업데이트", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: .teal) {
                Task { await updatePushPreference() }
            }
            .padding(.horizontal)

            HStack {
                TextField("FCM Token", text: $deviceTokenText)
                    .textFieldStyle(.roundedBorder)
                TextField("Device ID", text: $deviceIDText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)

            demoButton("디바이스 토큰 등록", bg: Color(red: 1.0, green: 0.94, blue: 0.88), fg: .orange) {
                Task { await registerDeviceToken() }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private func demoButton(
        _ title: String,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(fg)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !demoLogger.output.isEmpty {
                Text("Repository Log")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                ScrollView {
                    Text(demoLogger.output)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 100)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .padding(.horizontal)
            }

            Text("Result")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            ScrollView {
                Text(log)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }

    // MARK: - Computed

    private var notificationID: NotificationID? {
        guard let value = Int(notificationIDText) else { return nil }
        return NotificationID(value)
    }

    private var lastNotificationID: NotificationID? {
        guard let value = Int(lastIDText) else { return nil }
        return NotificationID(value)
    }

    private var pageSize: Int {
        Int(sizeText) ?? 20
    }

    // MARK: - Actions

    private func loadUnreadStatus() async {
        demoLogger.clear()
        log = "📤 loadUnreadNotificationStatus\n  (no params)"
        isLoading = true; defer { isLoading = false }
        do {
            let status = try await notifRepo.loadUnreadNotificationStatus()
            log += "\n\n✅ 성공\n미읽음 존재: \(status.hasUnreadNotifications)"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func loadNotifications() async {
        demoLogger.clear()
        log = "📤 loadNotifications\n  lastID: \(lastIDText.isEmpty ? "nil" : lastIDText)\n  size: \(pageSize)"
        isLoading = true; defer { isLoading = false }
        do {
            let paged = try await notifRepo.loadNotifications(
                lastNotificationID: lastNotificationID,
                size: pageSize
            )
            log += "\n\n" + formatNotifications(paged)
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func loadDetail() async {
        guard let notificationID else { log = "알림 ID를 입력해주세요."; return }
        demoLogger.clear()
        log = "📤 loadNotificationDetail\n  notificationID: \(notificationID.value)"
        isLoading = true; defer { isLoading = false }
        do {
            let detail = try await notifRepo.loadNotificationDetail(id: notificationID)
            log += "\n\n✅ 성공\n제목: \(detail.title)\n본문: \(detail.body)\n날짜: \(detail.createdAtText)"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func markAsRead() async {
        guard let notificationID else { log = "알림 ID를 입력해주세요."; return }
        notificationIDText = ""
        demoLogger.clear()
        log = "📤 markAsRead\n  notificationID: \(notificationID.value)"
        isLoading = true; defer { isLoading = false }
        do {
            try await notifRepo.markAsRead(id: notificationID)
            log += "\n\n✅ 성공"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func loadPushPreference() async {
        demoLogger.clear()
        log = "📤 loadPushPreference\n  (no params)"
        isLoading = true; defer { isLoading = false }
        do {
            let pref = try await pushRepo.loadPushPreference()
            isPushEnabled = pref.isEnabled
            log += "\n\n✅ 성공\n활성화: \(pref.isEnabled)"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func updatePushPreference() async {
        demoLogger.clear()
        log = "📤 updatePushPreference\n  isEnabled: \(isPushEnabled)"
        isLoading = true; defer { isLoading = false }
        do {
            try await pushRepo.updatePushPreference(PushPreference(isEnabled: isPushEnabled))
            log += "\n\n✅ 성공"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    private func registerDeviceToken() async {
        guard !deviceTokenText.isEmpty else { log = "FCM Token을 입력해주세요."; return }
        guard !deviceIDText.isEmpty    else { log = "Device ID를 입력해주세요."; return }
        demoLogger.clear()
        log = "📤 registerDeviceToken\n  token: \(deviceTokenText)\n  deviceID: \(deviceIDText)"
        isLoading = true; defer { isLoading = false }
        let token = DevicePushToken(token: deviceTokenText, deviceID: deviceIDText)
        do {
            try await pushRepo.registerDeviceToken(token)
            log += "\n\n✅ 성공"
        } catch {
            log += "\n\n\(describeError(error))"
        }
    }

    // MARK: - Formatters

    private func formatNotifications(_ paged: PagedNotifications) -> String {
        let items = paged.items
        if items.isEmpty { return "알림 없음" }
        var text = "알림 \(items.count)개 (더 불러오기 가능: \(paged.isLoadable))\n\n"
        for item in items {
            text += "[\(item.id.value)] \(item.title) (\(item.isRead ? "읽음" : "미읽음"))\n"
        }
        return text
    }
}
