//
//  FeedDraft.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct FeedDraft {
    
    public private(set) var content: String
    public private(set) var genre: [NovelGenre]
    public private(set) var isSpoiler: Bool
    public private(set) var isPrivate: Bool
    public private(set) var connectedNovel: ConnectedNovel?
    public private(set) var attachedImages: [ImageWrapper]
    
    // MARK: - init
    
    public init(
        content: String,
        genre: [NovelGenre],
        isSpoiler: Bool,
        isPrivate: Bool,
        connectedNovel: ConnectedNovel? = nil,
        attachedImages: [ImageWrapper]
    ) {
        let uniqueGenre = Array(Set(genre))
        let limitedImages = Array(attachedImages.prefix(Self.maxImageCount))
        
#if DEBUG
        if content.count > Self.maxContentCount {
            assertionFailure("Content overflow: \(content.count) (max: \(Self.maxContentCount))")
        }
        if uniqueGenre.count != genre.count {
            assertionFailure("Genre contains duplicates")
        }
        if attachedImages.count > Self.maxImageCount {
            assertionFailure("Image overflow: \(attachedImages.count) (max: \(Self.maxImageCount))")
        }
#endif
        
        self.content = content
        self.genre = uniqueGenre
        self.isSpoiler = isSpoiler
        self.isPrivate = isPrivate
        self.connectedNovel = connectedNovel
        self.attachedImages = limitedImages
    }
    
    // MARK: - Policy
    
    private static let maxContentCount: Int = 2000
    private static let maxImageCount: Int = 5
    
    public enum ValidationError: Error, Equatable {
        case contentOverLimit(max: Int)
        case imageOverLimit(max: Int)
        case connectedNovelOverLimit
        case emptyContent
        case emptyGenre
    }
    
    public mutating func updateContent(_ newValue: String) throws {
        guard newValue.count <= Self.maxContentCount else {
            throw ValidationError.contentOverLimit(max: Self.maxContentCount)
        }
        
        content = newValue
    }
    
    public func remainsContentCount() -> Int {
        Self.maxContentCount - content.count
    }
    
    public mutating func addGenre(_ newGenre: NovelGenre) {
        guard !genre.contains(newGenre) else { return }
        
        genre.append(newGenre)
    }
    
    public mutating func removeGenre(_ targetGenre: NovelGenre) {
        genre.removeAll { $0 == targetGenre }
    }
    
    public mutating func togglePrivate() {
        isPrivate.toggle()
    }
    
    public mutating func toggleSpoiler() {
        isSpoiler.toggle()
    }
    
    public mutating func setConnectedNovel(_ newValue: ConnectedNovel) throws {
        guard connectedNovel == nil else {
            throw ValidationError.connectedNovelOverLimit
        }
        
        connectedNovel = newValue
    }
    
    public mutating func removeConnectedNovel() {
        connectedNovel = nil
    }
    
    public mutating func addImage(_ image: ImageWrapper) throws {
        guard attachedImages.count < Self.maxImageCount else {
            throw ValidationError.imageOverLimit(max: Self.maxImageCount)
        }
        
        attachedImages.append(image)
    }
    
    public mutating func removeImage(_ image: ImageWrapper) {
        attachedImages.removeAll { $0 == image }
    }
}
