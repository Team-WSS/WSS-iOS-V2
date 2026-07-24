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
        let genrePreferences = try response.genrePreferences.map { try novelGenre(from: $0) }
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
        case "worldView":       return .worldview
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

    /// userDefaults 로컬 저장 포맷. 계정정보 API(`gender(from:)`/`genderRawValue(from:)`)의 "M"/"F"와 다르다 —
    /// `syncUserBasicInfo()`가 `UserInfoResponse.gender`(예: "MALE"/"FEMALE")를 원문 그대로 저장하기 때문.
    static func localGender(from text: String) throws -> Gender {
        switch text {
        case "MALE":    return .male
        case "FEMALE":  return .female
        default:
            throw MappingError.invalidConversion(type: "Gender", value: text)
        }
    }

    static func localGenderRawValue(from gender: Gender) -> String {
        switch gender {
        case .male:     return "MALE"
        case .female:   return "FEMALE"
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
