//
//  ImageWrapper.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

// URL값이 없거나, 제대로된 값이 오지 않았을 때 -> 디폴트 이미지를 넣어야 함.
// 도메인 관점에서 이미지 타입을 URL? 로 두는 게 맞음? 아닌 거 같은데 ..
// 지피티 ㄱㄱ -> ImageWrapper로 감싸라~

//TODO:  좀 더 수정을 해봐야겠따..
public struct ImageWrapper: Equatable {
    // url..?
    public let identifier: String
    
    public init(identifier: String) {
        self.identifier = identifier
    }
}
