//
//  ChatError.swift
//  Chat
//
//  Created by 杨志远 on 2023/3/8.
//

import Foundation

enum ChatError: Error {
    case none
    case noAPIKey
    case noQuestion
    case isWorking
    case request(message: String)

    var message: String {
        switch self {
        case .none:
            return ""
        case .noAPIKey:
            return R.Text.apiKeyDesc
        case .isWorking:
            return R.Text.loading
        case .noQuestion:
            return R.Text.enterYourQuestion
        case let .request(value):
            return value
        }
    }
}

extension ChatError: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.noAPIKey, .noAPIKey):
            return true
        case (.isWorking, .isWorking):
            return true
        case (.noQuestion, .noQuestion):
            return true
        case (.request, .request):
            return true
        default:
            return false
        }
    }
}
