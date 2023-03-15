import Foundation

enum ChatRole : String,Codable {
    case system
    case user
    case assistant
}

struct ChatMessage: Identifiable, Hashable, Encodable {
    let id: String = UUID().uuidString
    let role: ChatRole
    var message: String
    let isReceived: Bool
    
    enum CodingKeys: String,CodingKey {
        case role
        case message = "content"
    }
}


// 两张表：sessioninfo         sessiondetail

// sessioninfo
// int id; name string;
// sessiondetail
// int id; int sessionId; message string;
