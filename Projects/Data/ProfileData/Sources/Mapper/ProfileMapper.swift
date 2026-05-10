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
            characterImage: URL(string: response.avatarImage),
            isPublic: response.isProfilePublic ?? false,
            genrePreferences: genrePreferences
        )
    }

    static func genrePreferences(from preferences: [GenrePreferences]) -> [GenrePreference] {
        preferences.map { pref in
            GenrePreference(
                name: pref.genreName,
                image: URL(string: pref.genreImage),
                count: pref.genreCount
            )
        }
    }
    
    static func novelPreference(
        from response: NovelPreferenceResponse,
        keywordLookup: [String: KeywordID]
    ) throws -> NovelPreference {
        let attractivePoints = try response.attractivePoints.map { try attractivePoint(from: $0) }
        var keywords: [Keyword: Int] = [:]
        for preference in response.keywords {
            let keyword = Keyword(
                id: keywordLookup[preference.keywordName] ?? KeywordID(-1),
                name: preference.keywordName
            )
            keywords[keyword] = preference.keywordCount
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
                representativeImage: URL(string: avatar.avatarCharacterImage),
                thumbnailImage: URL(string: avatar.avatarProfileImage),
                isRepresentative: avatar.isRepresentative
            )
        }
    }

    static func profileDraft(
        from response: UserProfileResponse,
        characterID: Int
    ) -> ProfileDraft {
        let genrePreferences = response.genrePreferences.map {
            GenrePreference(name: $0, image: nil, count: 0)
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
        case "writingSkill":    return .writingSkill
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
}
