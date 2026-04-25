//
//  ProfileCharacter.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ProfileCharacter {
    
    public let id: Int
    
    public let name: String
    public let line: String
    
    public let representativeImage: URL?
    public let thumbnailImage: URL?

    public let isRepresentative: Bool
    
    public init(
        id: Int,
        name: String,
        line: String,
        representativeImage: URL?,
        thumbnailImage: URL?,
        isRepresentative: Bool
    ) {
        self.id = id
        self.name = name
        self.line = line
        self.representativeImage = representativeImage
        self.thumbnailImage = thumbnailImage
        self.isRepresentative = isRepresentative
    }
}
