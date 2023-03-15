//
//  ChatRequest.swift
//  Chat
//
//  Created by 杨志远 on 2023/3/8.
//

import Foundation

struct ChatRequest : Encodable {
    let model: String = "gpt-3.5-turbo"
    let temperature: Double = 0.5
    let messages: [ChatMessage]
    let stream: Bool = true
}
