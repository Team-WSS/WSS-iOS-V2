//
//  Post.swift
//  Networking
//
//  Created by YunhakLee on 10/30/25.
//

import Foundation

struct Post: Codable, CustomStringConvertible {
    let id: Int?
    let title: String
    let body: String
    let userId: Int?
    
    var description: String {
        """
        id: \(id ?? -1)
        title: \(title)
        body: \(body)
        userId: \(userId ?? -1)
        """
    }
}
