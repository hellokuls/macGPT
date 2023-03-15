//
//  ChatResponse.swift
//  Chat
//
//  Created by 杨志远 on 2023/3/8.
//

import Foundation


struct ChatResponse: Decodable {
    let choices: [ChatResponseChoice]
}

struct ChatResponseChoice: Decodable {
    let finishReason: String?
    let delta: ChatResponseMessage
}

struct ChatResponseMessage: Decodable {
    let content: String?
    let role: String?
}


struct ChatResponseError: Decodable {
    let error: ChatResponseErrorEntity
}

struct ChatResponseErrorEntity: Decodable {
    let message: String
    let type: String?
}
