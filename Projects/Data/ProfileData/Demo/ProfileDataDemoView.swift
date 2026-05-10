//
//  ProfileDataDemoView.swift
//  ProfileDataDemo
//
//  Created by WonsunLee on 5/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import ProfileData
import ProfileDomain
import BaseDomain
import Networking
import BaseData
import Logger

struct ProfileDataDemoView: View {
    @State private var log: String = "버튼을 눌러 API를 호출하세요."
    @State private var nicknameText: String = ""
    @State private var otherUserIDText: String = ""
    @State private var isLoading: Bool = false

    // 계정 정보 수정
    @State private var accountGender: String = "F"
    @State private var accountBirthText: String = "1996"

    // 프로필 수정
    @State private var updateAvatarIdText: String = ""
    @State private var updateNicknameText: String = "닉넹임"
    @State private var updateIntroText: String = ""

    // 프로필 등록
    @State private var regNicknameText: String = ""
    @State private var regGender: String = "F"
    @State private var regBirthText: String = "1996"

    private let repository: ProfileRepository
    private let keywordRepository: KeywordRepository
    private let localStorage: UserDefaultsStorage

    private var myUserID: Int { localStorage.get(.userID) ?? 0 }

    init() {
        let client = NetworkingClient()
        let storage = UserDefaultsStorage()
        let logger = DataLogger(moduleName: "ProfileData", underlying: OSLogger.profile)
        storage.set(.userID, 10033)
        storage.set(.nickname, "닉넹임")
        storage.set(.gender, "F")
        self.localStorage = storage
        self.keywordRepository = KeywordDataFactory.makeRepository(client: client, logger: logger)
        self.repository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: storage,
            logger: logger
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    myProfileSection
                    Divider()
                    nicknameSection
                    Divider()
                    otherUserSection
                    Divider()
                    updateSection
                    logSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile Demo")
        }
    }

    // MARK: - Sections

    private var myProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Profile").font(.headline).padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                demoButton("기본 정보 동기화", bg: Color(red: 0.95, green: 0.95, blue: 0.95), fg: Color(red: 0.3, green: 0.3, blue: 0.3)) {
                    Task { await syncUserBasicInfo() }
                }
                demoButton("내 프로필 조회", bg: Color(red: 0.88, green: 0.94, blue: 1.0), fg: Color(red: 0.2, green: 0.4, blue: 0.9)) {
                    Task { await fetchMyProfile() }
                }
                demoButton("장르 선호도 조회", bg: Color(red: 0.92, green: 0.88, blue: 1.0), fg: Color(red: 0.45, green: 0.2, blue: 0.85)) {
                    Task { await fetchMyGenrePreferences() }
                }
                demoButton("키워드 동기화", bg: Color(red: 1.0, green: 0.97, blue: 0.88), fg: Color(red: 0.65, green: 0.45, blue: 0.0)) {
                    Task { await syncKeywords() }
                }
                demoButton("소설 선호도 조회", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: Color(red: 0.1, green: 0.55, blue: 0.45)) {
                    Task { await fetchMyNovelPreferences() }
                }
                demoButton("프로필 캐릭터 목록", bg: Color(red: 1.0, green: 0.95, blue: 0.88), fg: Color(red: 0.7, green: 0.4, blue: 0.1)) {
                    Task { await fetchProfileCharacters() }
                }
                demoButton("계정 정보 조회", bg: Color(red: 0.92, green: 0.90, blue: 0.99), fg: Color(red: 0.35, green: 0.3, blue: 0.7)) {
                    Task { await loadAccountInfoDraft() }
                }
                demoButton("공개 여부 조회", bg: Color(red: 0.98, green: 0.93, blue: 0.88), fg: Color(red: 0.75, green: 0.35, blue: 0.1)) {
                    Task { await loadProfileVisibility() }
                }
            }
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("닉네임 중복 확인").font(.headline).padding(.horizontal)

            HStack {
                TextField("닉네임 입력", text: $nicknameText)
                    .textFieldStyle(.roundedBorder)
                demoButton("중복 확인", bg: Color(red: 0.90, green: 0.97, blue: 0.90), fg: Color(red: 0.15, green: 0.55, blue: 0.25)) {
                    Task { await validateNickname() }
                }
            }
            .padding(.horizontal)
            .disabled(isLoading)
        }
    }

    private var otherUserSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다른 유저 프로필").font(.headline).padding(.horizontal)

            HStack {
                TextField("유저 ID", text: $otherUserIDText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                demoButton("프로필 조회", bg: Color(red: 0.88, green: 0.94, blue: 1.0), fg: Color(red: 0.2, green: 0.4, blue: 0.9)) {
                    Task { await fetchOtherUserProfile() }
                }
                demoButton("장르 선호도", bg: Color(red: 0.92, green: 0.88, blue: 1.0), fg: Color(red: 0.45, green: 0.2, blue: 0.85)) {
                    Task { await fetchOtherUserGenrePreferences() }
                }
                demoButton("소설 선호도", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: Color(red: 0.1, green: 0.55, blue: 0.45)) {
                    Task { await fetchOtherUserNovelPreferences() }
                }
            }
            .padding(.horizontal)
            .disabled(isLoading)
        }
    }

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("수정 / 등록").font(.headline).padding(.horizontal)

            // 공개 여부
            HStack(spacing: 8) {
                demoButton("공개로 변경", bg: Color(red: 0.88, green: 0.97, blue: 0.94), fg: Color(red: 0.1, green: 0.55, blue: 0.45)) {
                    Task { await updateVisibility(isPublic: true) }
                }
                demoButton("비공개로 변경", bg: Color(red: 1.0, green: 0.94, blue: 0.94), fg: Color(red: 0.75, green: 0.2, blue: 0.2)) {
                    Task { await updateVisibility(isPublic: false) }
                }
            }
            .padding(.horizontal)

            Divider().padding(.horizontal)

            // 계정 정보 수정
            VStack(alignment: .leading, spacing: 6) {
                Text("계정 정보 수정").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                HStack {
                    Picker("성별", selection: $accountGender) {
                        Text("F").tag("F")
                        Text("M").tag("M")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                    TextField("출생연도 (예: 1996)", text: $accountBirthText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    demoButton("수정", bg: Color(red: 0.92, green: 0.90, blue: 0.99), fg: Color(red: 0.35, green: 0.3, blue: 0.7)) {
                        Task { await saveAccountInfo() }
                    }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            // 프로필 수정
            VStack(alignment: .leading, spacing: 6) {
                Text("프로필 수정 (genrePreferences: [\"fantasy\"] 고정)").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                HStack {
                    TextField("avatarId", text: $updateAvatarIdText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    TextField("닉네임", text: $updateNicknameText)
                        .textFieldStyle(.roundedBorder)
                    TextField("소개글", text: $updateIntroText)
                        .textFieldStyle(.roundedBorder)
                    demoButton("수정", bg: Color(red: 0.88, green: 0.94, blue: 1.0), fg: Color(red: 0.2, green: 0.4, blue: 0.9)) {
                        Task { await updateProfile() }
                    }
                }
                .padding(.horizontal)
            }

            Divider().padding(.horizontal)

            // 프로필 등록
            VStack(alignment: .leading, spacing: 6) {
                Text("프로필 등록 (장르: romanceFantasy, fantasy)").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                HStack {
                    TextField("닉네임", text: $regNicknameText)
                        .textFieldStyle(.roundedBorder)
                    Picker("성별", selection: $regGender) {
                        Text("F").tag("F")
                        Text("M").tag("M")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                    TextField("출생연도", text: $regBirthText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    demoButton("등록", bg: Color(red: 1.0, green: 0.95, blue: 0.88), fg: Color(red: 0.7, green: 0.4, blue: 0.1)) {
                        Task { await registerProfile() }
                    }
                }
                .padding(.horizontal)
            }
        }
        .disabled(isLoading)
    }

    private var logSection: some View {
        ScrollView {
            Text(log)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .frame(minHeight: 200)
    }

    // MARK: - demoButton

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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(bg)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func syncUserBasicInfo() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/me"
        do {
            try await repository.syncUserBasicInfo()
            log = "endpoint: .getUserInfo\n[GET] \(url)\n\n기본 정보 동기화 완료\nuserID: \(myUserID)"
        } catch {
            log = "endpoint: .getUserInfo\n[GET] \(url)\n\n기본 정보 동기화 실패\n\(error)"
        }
    }

    private func fetchMyProfile() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile"
        do {
            let draft = try await repository.loadInitialProfile()
            log = "endpoint: .getProfileInfo\n[GET] \(url)\n\n닉네임: \(draft.nickname.text)\n소개: \(draft.introduction)\n장르: \(draft.genrePreferences.map { $0.name }.joined(separator: ", "))"
        } catch {
            log = "endpoint: .getProfileInfo\n[GET] \(url)\n\n내 프로필 조회 실패\n\(error)"
        }
    }

    private func fetchMyGenrePreferences() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/\(myUserID)/preferences/genres"
        do {
            let genres = try await repository.fetchGenrePreferences(.me)
            let list = genres.map { "\($0.name): \($0.count)" }.joined(separator: "\n")
            log = "endpoint: .getGenrePreferences(userID: \(myUserID))\n[GET] \(url)\n\n\(list)"
        } catch {
            log = "endpoint: .getGenrePreferences(userID: \(myUserID))\n[GET] \(url)\n\n장르 선호도 조회 실패\n\(error)"
        }
    }

    private func syncKeywords() async {
        isLoading = true; defer { isLoading = false }
        await keywordRepository.syncKeywords()
        log = "키워드 동기화 완료\n이제 소설 선호도 조회를 눌러보세요."
    }

    private func fetchMyNovelPreferences() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/\(myUserID)/preferences/attractive-points"
        do {
            let prefs = try await repository.fetchNovelPreferences(.me)
            let points = prefs.attractivePoints.map { "\($0)" }.joined(separator: ", ")
            let keywords = prefs.keywords
                .map { "\($0.key.name)(id: \($0.key.id.value)): \($0.value)" }
                .sorted()
                .joined(separator: "\n")
            log = "endpoint: .getNovelPreferences(userID: \(myUserID))\n[GET] \(url)\n\n매력 포인트: \(points)\n\n키워드:\n\(keywords)"
        } catch {
            log = "endpoint: .getNovelPreferences(userID: \(myUserID))\n[GET] \(url)\n\n소설 선호도 조회 실패\n\(error)"
        }
    }

    private func fetchProfileCharacters() async {
        isLoading = true; defer { isLoading = false }
        let url = "/avatar-profiles"
        do {
            let characters = try await repository.fetchProfileCharacters()
            let list = characters.enumerated().map { i, c in "[\(i+1)] ID: \(c.id)" }.joined(separator: "\n")
            log = "endpoint: .getProfileAvatars\n[GET] \(url)\n\n캐릭터 목록 (\(characters.count)개)\n\(list)"
        } catch {
            log = "endpoint: .getProfileAvatars\n[GET] \(url)\n\n캐릭터 목록 조회 실패\n\(error)"
        }
    }

    private func loadAccountInfoDraft() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/info"
        do {
            let draft = try await repository.loadAccountInfoDraft()
            log = "endpoint: .getAccountInfo\n[GET] \(url)\n\n성별: \(draft.gender)\n출생연도: \(draft.birth.value)"
        } catch {
            log = "endpoint: .getAccountInfo\n[GET] \(url)\n\n계정 정보 조회 실패\n\(error)"
        }
    }

    private func loadProfileVisibility() async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile-status"
        do {
            let visibility = try await repository.loadProfileVisibility()
            log = "endpoint: .getProfileVisibility\n[GET] \(url)\n\n공개 여부: \(visibility.isPublic ? "공개" : "비공개")"
        } catch {
            log = "endpoint: .getProfileVisibility\n[GET] \(url)\n\n공개 여부 조회 실패\n\(error)"
        }
    }

    private func validateNickname() async {
        let nickname = nicknameText
        guard !nickname.isEmpty else { log = "닉네임을 입력해주세요."; return }
        nicknameText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/nickname/check?nickname=\(nickname)"
        do {
            let isValid = try await repository.validateNickname(nickname)
            log = "endpoint: .validateNickname(\"\(nickname)\")\n[GET] \(url)\n\nisValid: \(isValid)\n'\(nickname)': \(isValid ? "사용 가능" : "불가")"
        } catch {
            log = "endpoint: .validateNickname(\"\(nickname)\")\n[GET] \(url)\n\n닉네임 확인 실패\n\(error)"
        }
    }

    private func fetchOtherUserProfile() async {
        guard let userID = Int(otherUserIDText) else { log = "유저 ID를 입력해주세요."; return }
        otherUserIDText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile/\(userID)"
        do {
            let profile = try await repository.fetchUserProfile(target: .user(UserID(userID)))
            log = "endpoint: .getUserProfile(userID: \(userID))\n[GET] \(url)\n\n닉네임: \(profile.nickname)\n소개: \(profile.introduction)\n공개: \(profile.isPublic)"
        } catch {
            log = "endpoint: .getUserProfile(userID: \(userID))\n[GET] \(url)\n\n유저 프로필 조회 실패\n\(error)"
        }
    }

    private func fetchOtherUserGenrePreferences() async {
        guard let userID = Int(otherUserIDText) else { log = "유저 ID를 입력해주세요."; return }
        otherUserIDText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/\(userID)/preferences/genres"
        do {
            let genres = try await repository.fetchGenrePreferences(.user(UserID(userID)))
            let list = genres.map { "\($0.name): \($0.count)" }.joined(separator: "\n")
            log = "endpoint: .getGenrePreferences(userID: \(userID))\n[GET] \(url)\n\n\(list)"
        } catch {
            log = "endpoint: .getGenrePreferences(userID: \(userID))\n[GET] \(url)\n\n장르 선호도 조회 실패\n\(error)"
        }
    }

    private func fetchOtherUserNovelPreferences() async {
        guard let userID = Int(otherUserIDText) else { log = "유저 ID를 입력해주세요."; return }
        otherUserIDText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/\(userID)/preferences/attractive-points"
        do {
            let prefs = try await repository.fetchNovelPreferences(.user(UserID(userID)))
            let points = prefs.attractivePoints.map { "\($0)" }.joined(separator: ", ")
            let keywords = prefs.keywords
                .map { "\($0.key.name)(id: \($0.key.id.value)): \($0.value)" }
                .sorted()
                .joined(separator: "\n")
            log = "endpoint: .getNovelPreferences(userID: \(userID))\n[GET] \(url)\n\n매력 포인트: \(points)\n\n키워드:\n\(keywords)"
        } catch {
            log = "endpoint: .getNovelPreferences(userID: \(userID))\n[GET] \(url)\n\n소설 선호도 조회 실패\n\(error)"
        }
    }

    private func updateVisibility(isPublic: Bool) async {
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile-status"
        do {
            try await repository.updateProfileVisibility(ProfileVisibility(isPublic: isPublic))
            log = "endpoint: .patchProfileVisibility\n[PATCH] \(url)\n파라미터: isProfilePublic=\(isPublic)\n\n공개 여부 변경 완료"
        } catch {
            log = "endpoint: .patchProfileVisibility\n[PATCH] \(url)\n파라미터: isProfilePublic=\(isPublic)\n\n공개 여부 변경 실패\n\(error)"
        }
    }

    private func saveAccountInfo() async {
        guard let birth = Int(accountBirthText) else { log = "출생연도를 올바르게 입력해주세요."; return }
        isLoading = true; defer { isLoading = false }
        let url = "/users/info"
        do {
            let gender: Gender = accountGender == "M" ? .male : .female
            let draft = AccountInfoDraft(
                email: nil,
                gender: gender,
                birth: try BirthYear(birth)
            )
            try await repository.saveAccountInfo(draft)
            log = "endpoint: .patchAccountInfo\n[PATCH] \(url)\n파라미터: gender=\(accountGender), birth=\(birth)\n\n계정 정보 수정 완료"
        } catch {
            log = "endpoint: .patchAccountInfo\n[PATCH] \(url)\n파라미터: gender=\(accountGender), birth=\(birth)\n\n계정 정보 수정 실패\n\(error)"
        }
    }

    private func registerProfile() async {
        guard !regNicknameText.isEmpty else { log = "닉네임을 입력해주세요."; return }
        guard let birth = Int(regBirthText) else { log = "출생연도를 올바르게 입력해주세요."; return }
        let nickname = regNicknameText
        regNicknameText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile"
        do {
            let gender: Gender = regGender == "M" ? .male : .female
            let registration = ProfileRegistration(
                nickname: nickname,
                gender: gender,
                birthYear: try BirthYear(birth),
                genrePreferences: [.romanceFantasy, .fantasy]
            )
            try await repository.registerProfile(registration)
            log = "endpoint: .postRegisterProfile\n[POST] \(url)\n파라미터: nickname=\(nickname), gender=\(regGender), birth=\(birth), genres=[romanceFantasy, fantasy]\n\n프로필 등록 완료"
        } catch {
            log = "endpoint: .postRegisterProfile\n[POST] \(url)\n파라미터: nickname=\(nickname), gender=\(regGender), birth=\(birth)\n\n프로필 등록 실패\n\(error)"
        }
    }

    private func updateProfile() async {
        let avatarId = Int(updateAvatarIdText) ?? (localStorage.get(.characterID) ?? 0)
        let nickname = updateNicknameText
        let intro = updateIntroText
        updateAvatarIdText = ""
        updateIntroText = ""
        isLoading = true; defer { isLoading = false }
        let url = "/users/profile"
        do {
            var draft = ProfileDraft(
                characterID: avatarId,
                nickname: nickname,
                introduction: intro,
                genrePreferences: []
            )
            draft.addGenrePreference(GenrePreference(name: "fantasy", image: nil, count: 0))
            try await repository.updateProfile(draft)
            log = "endpoint: .patchProfile\n[PATCH] \(url)\n파라미터: avatarId=\(avatarId), nickname=\(nickname), intro=\(intro), genrePreferences=[\"fantasy\"]\n\n프로필 수정 완료"
        } catch {
            log = "endpoint: .patchProfile\n[PATCH] \(url)\n파라미터: avatarId=\(avatarId), nickname=\(nickname), intro=\(intro)\n\n프로필 수정 실패\n\(error)"
        }
    }
}
