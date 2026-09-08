//
//  ProfileMapper.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import ProfileDomain
import BaseDomain
import BaseData

enum ProfileMapper {

    static func profile(from response: UserProfileResponse) throws -> Profile {
        // `genrePreferences`는 이 응답의 소비자(UserPage/MyPage 상단 프로필)가 실제로 쓰지 않는 필드다
        // (닉네임·소개·프로필 이미지만 화면에 반영됨) — 그래서 `try`가 아니라 `try?`로 관대하게 매핑한다.
        // 여기서 하나라도 못 알아듣는 장르 문자열 때문에 전체 프로필 매핑이 실패하면, 정작 필요한
        // 닉네임/소개/이미지까지 함께 버려진다(#255 QA 실측 — 비공개 유저 상단 정보가 이 이유로 안 보일
        // 뻔했다).
        let genrePreferences = response.genrePreferences.compactMap { try? novelGenre(from: $0) }
        return Profile(
            nickname: response.nickname,
            introduction: response.intro,
            characterImage: ImageURLResolver.resolve(from: response.avatarImage),
            isPublic: response.isProfilePublic ?? false,
            genrePreferences: genrePreferences
        )
    }

    static func genrePreferences(from preferences: [GenrePreferences]) throws -> [GenrePreference] {
        try preferences.map { pref in
            GenrePreference(
                genre: try novelGenre(from: pref.genreName),
                count: pref.genreCount
            )
        }
    }
    
    static func novelPreference(
        from response: NovelPreferenceResponse,
        keywordLookup: [String: KeywordID]
    ) throws -> NovelPreference {
        let attractivePoints = try response.attractivePoints.map { try attractivePoint(from: $0) }
        let keywords = response.keywords.map { preference in
            KeywordPreference(
                keyword: Keyword(
                    id: keywordLookup[preference.keywordName] ?? KeywordID(-1),
                    name: preference.keywordName
                ),
                count: preference.keywordCount
            )
        }
        return NovelPreference(
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }

    static func profileAvatars(from response: ProfileAvatarResponse) -> [ProfileCharacter] {
        response.avatarProfiles.map { avatar in
            ProfileCharacter(
                id: avatar.avatarProfileId,
                name: avatar.avatarProfileName,
                line: avatar.avatarProfileLine,
                representativeImage: ImageURLResolver.resolve(from: avatar.avatarCharacterImage),
                thumbnailImage: ImageURLResolver.resolve(from: avatar.avatarProfileImage),
                isRepresentative: avatar.isRepresentative
            )
        }
    }

    static func profileDraft(
        from response: UserProfileResponse,
        characterID: Int
    ) throws -> ProfileDraft {
        let genrePreferences = try response.genrePreferences.map {
            GenrePreference(genre: try novelGenre(from: $0), count: 0)
        }
        return ProfileDraft(
            characterID: characterID,
            nickname: response.nickname,
            introduction: response.intro,
            genrePreferences: genrePreferences
        )
    }

    static func accountInfoDraft(from response: AccountInfoResponse) throws -> AccountInfoDraft {
        let birth: BirthYear
        do {
            birth = try BirthYear(response.birth)
        } catch {
            throw MappingError.invalidPayload(reason: "Invalid birthYear: \(response.birth)")
        }
        let gender = try ProfileMapper.gender(from: response.gender)
        return AccountInfoDraft(
            email: response.email,
            gender: gender,
            birth: birth
        )
    }

    static func novelGenre(from text: String) throws -> NovelGenre {
        switch text {
        case "lightNovel":         return .lightNovel
        case "wuxia":              return .wuxia
        case "fantasy":            return .fantasy
        case "romance":            return .romance
        case "BL":                 return .BL
        case "romanceFantasy":     return .romanceFantasy
        case "modernFantasy":      return .modernFantasy
        case "drama":              return .drama
        case "mystery":            return .mystery
        default:
            throw MappingError.invalidConversion(type: "NovelGenre", value: text)
        }
    }

    static func attractivePoint(from text: String) throws -> AttractivePoint {
        switch text {
        case "worldview":       return .worldview
        case "material":        return .material
        case "character":       return .character
        case "relationship":    return .relationship
        case "vibe":            return .vibe
        case "writingskill":    return .writingSkill
        default:
            throw MappingError.invalidConversion(type: "AttractivePoint", value: text)
        }
    }

    static func gender(from text: String) throws -> Gender {
        switch text {
        case "M":   return .male
        case "F":   return .female
        default:
            throw MappingError.invalidConversion(type: "Gender", value: text)
        }
    }

    static func novelGenreRawValue(from genre: NovelGenre) -> String {
        switch genre {
        case .lightNovel:       return "lightNovel"
        case .wuxia:            return "wuxia"
        case .fantasy:          return "fantasy"
        case .romance:          return "romance"
        case .BL:               return "BL"
        case .romanceFantasy:   return "romanceFantasy"
        case .modernFantasy:    return "modernFantasy"
        case .drama:            return "drama"
        case .mystery:          return "mystery"
        }
    }

    static func genderRawValue(from gender: Gender) -> String {
        switch gender {
        case .male:     return "M"
        case .female:   return "F"
        }
    }

    /// userDefaults 로컬 저장 포맷. **서버가 "MALE"/"FEMALE"에서 "M"/"F"로 통일하면서(2026-09-08 실측
    /// — `GET /users/info`도 이제 계정정보 API와 동일하게 "M"/"F"를 준다) 계정정보 API 포맷과 같아졌다.**
    /// 새로 쓰는 값은 전부 "M"/"F"지만, 이 변경 전에 이미 "MALE"/"FEMALE"로 캐시된 기존 설치는 그대로
    /// 남아있으므로 하위 호환으로 계속 받아들인다 — 안 받아주면 그 기기는 캐시가 새로 쓰일 때까지
    /// "성별/나이 변경" 화면 진입마다 매핑 에러가 난다.
    static func localGender(from text: String) throws -> Gender {
        switch text {
        case "M", "MALE":   return .male
        case "F", "FEMALE": return .female
        default:
            throw MappingError.invalidConversion(type: "Gender", value: text)
        }
    }

    static func localGenderRawValue(from gender: Gender) -> String {
        switch gender {
        case .male:     return "M"
        case .female:   return "F"
        }
    }

    /// userDefaults에서 읽은 원시값(성별 문자열·출생연도)을 `AccountInfoDraft`로 변환한다. (email 없음)
    static func localGenderAndBirth(genderRaw: String, birthValue: Int) throws -> AccountInfoDraft {
        let birth: BirthYear
        do {
            birth = try BirthYear(birthValue)
        } catch {
            throw MappingError.invalidPayload(reason: "Invalid birthYear: \(birthValue)")
        }
        let gender = try ProfileMapper.localGender(from: genderRaw)
        return AccountInfoDraft(email: nil, gender: gender, birth: birth)
    }
}
