//
//  SessionDetail.swift
//  Chat
//
//  Created by kuls on 2023/3/13.
//

import Foundation

struct SessionDetail: Hashable, Encodable, Identifiable {
    var uuid: String = UUID().uuidString
    var id: Int32
    var name: String
}
