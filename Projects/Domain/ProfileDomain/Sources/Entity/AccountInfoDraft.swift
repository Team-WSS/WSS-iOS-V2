//
//  AccountInfoDraft.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public struct AccountInfoDraft: Equatable {
    
    public let email: String?
    public private(set) var gender: Gender
    public private(set) var birth: BirthYear
    
    // MARK: - Init
    
    public init(email: String?, gender: Gender, birth: BirthYear) {
        self.email = email
        self.gender = gender
        self.birth = birth
    }
    
    // MARK: - Mutating
    
    mutating func setGender(_ gender: Gender) {
        self.gender = gender
    }
    
    mutating func setBirth(_ birth: BirthYear) {
        self.birth = birth
    }
}
