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
            isPublic: response.isProfilePblic,
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
    
    // TODO: 그때 우리 키워드 ID 어떻게 하기로 했었죠....? 검색에 사용하는 키워드 검색 API를 가져오기로 했었...나..?
    static func novelPreference(from response: NovelPreferenceResponse) throws -> NovelPreference {
        let attractivePoints = try response.attractivePoints.map { try attractivePoint(from: $0) }
        var keywords: [Keyword: Int] = [:]
        for preference in response.keywords {
            let keyword = Keyword(
                id: KeywordID(preference.keywordId),
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
        from response: ProfileEditInfoResponse,
        nickname: String,
        characterID: Int
    ) -> ProfileDraft {
        let genrePreferences = ProfileMapper.genrePreferences(from: response.genrePreferences)
        return ProfileDraft(
            characterID: characterID,
            nickname: nickname,
            introduction: response.introduction,
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
        case "LIGHT_NOVEL":     return .lightNovel
        case "WUXIA":           return .wuxia
        case "FANTASY":         return .fantasy
        case "ROMANCE":         return .romance
        case "BL":              return .BL
        case "ROMANCE_FANTASY": return .romanceFantasy
        case "MODERN_FANTASY":  return .modernFantasy
        case "DRAMA":           return .drama
        case "MYSTERY":         return .mystery
        default:
            throw MappingError.invalidConversion(type: "NovelGenre", value: text)
        }
    }

    static func attractivePoint(from text: String) throws -> AttractivePoint {
        switch text {
        case "WORLD_VIEW":      return .worldview
        case "MATERIAL":        return .material
        case "CHARACTER":       return .character
        case "RELATIONSHIP":    return .relationship
        case "VIBE":            return .vibe
        case "WRITING_SKILL":   return .writingSkill
        default:
            throw MappingError.invalidConversion(type: "AttractivePoint", value: text)
        }
    }

    static func gender(from text: String) throws -> Gender {
        switch text {
        case "MALE":    return .male
        case "FEMALE":  return .female
        default:
            throw MappingError.invalidConversion(type: "Gender", value: text)
        }
    }

    static func novelGenreRawValue(from genre: NovelGenre) -> String {
        switch genre {
        case .lightNovel:       return "LIGHT_NOVEL"
        case .wuxia:            return "WUXIA"
        case .fantasy:          return "FANTASY"
        case .romance:          return "ROMANCE"
        case .BL:               return "BL"
        case .romanceFantasy:   return "ROMANCE_FANTASY"
        case .modernFantasy:    return "MODERN_FANTASY"
        case .drama:            return "DRAMA"
        case .mystery:          return "MYSTERY"
        }
    }

    static func genderRawValue(from gender: Gender) -> String {
        switch gender {
        case .male:     return "MALE"
        case .female:   return "FEMALE"
        }
    }
}
