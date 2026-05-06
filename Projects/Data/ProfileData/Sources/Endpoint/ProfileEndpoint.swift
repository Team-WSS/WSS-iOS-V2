//
//  ProfileEndpoint.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking
import BaseData

enum ProfileEndpoint: Endpoint {
    case getUserInfo
    case validateNickname(ValidateNicknameQuery)
    case postRegisterProfile(ProfileRegistrationRequest)
    case getAccountInfo
    case putAccountInfo(AccountInfoRequest)
    case getProfileVisibility
    case patchProfileVisibility(ProfileVisibilityRequest)
    case getUserProfile(userID: Int)
    case getGenrePreferences(userID: Int)
    case getNovelPreferences(userID: Int)
    case getProfileAvatars
    case getProfileInfo
    case patchProfile(UpdateProfileRequest)

    var method: HTTPMethod {
        switch self {
        case .getUserInfo:              return .get
        case .validateNickname:         return .get
        case .postRegisterProfile:      return .post
        case .getProfileInfo:           return .get
        case .patchProfile:             return .patch
        case .getProfileVisibility:     return .get
        case .patchProfileVisibility:   return .patch
        case .getUserProfile:           return .get
        case .getGenrePreferences:      return .get
        case .getNovelPreferences:      return .get
        case .getProfileAvatars:        return .get
        case .getAccountInfo:           return .get
        case .putAccountInfo:           return .put
        }
    }

    var baseURL: URL {
        URL(string: NetworkingConfig.baseURL) ?? URL(string: "")!
    }

    var path: String {
        switch self {
        case .getUserInfo:                          return "/users/me"
        case .validateNickname:                     return "/users/nickname/check"
        case .postRegisterProfile:                  return "/users/profile"
        case .getProfileInfo:                       return "/users/profile"
        case .patchProfile:                         return "/users/profile"
        case .getProfileVisibility:                 return "/users/profile-status"
        case .patchProfileVisibility:               return "/users/profile-status"
        case .getUserProfile(let userID):           return "/users/profile/\(userID)"
        case .getGenrePreferences(let userID):      return "/users/\(userID)/preferences/genres"
        case .getNovelPreferences(let userID):      return "/users/\(userID)/preferences/attractive-points"
        case .getProfileAvatars:                    return "/avatar-profiles"
        case .getAccountInfo:                       return "/users/info"
        case .putAccountInfo:                       return "/users/info"
        }
    }
    
    var query: QueryParameters {
        switch self {
        case .validateNickname(let query): return .convertible(query)
        default: return .none
        }
    }
    
    var body: RequestBody {
        switch self {
        case .postRegisterProfile(let request):
            return .json(request)
        case .putAccountInfo(let request):
            return .json(request)
        case .patchProfileVisibility(let request):
            return .json(request)
        case .patchProfile(let request):
            return .json(request)
        default:
            return .none
        }
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var authorization: AuthorizationPolicy { .requiresToken }
}
