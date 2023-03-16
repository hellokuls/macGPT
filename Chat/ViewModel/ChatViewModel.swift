import Foundation
import AppKit
import SQLite3

private let API_KEY = "api_key"

class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var lastMessage: String = ""
    @Published private(set) var lastMessageID: String = ""
    @Published private(set) var isWorking: Bool = false
    @Published var apiKey: String = ""
    var db: OpaquePointer?
    @Published var chatErr: ChatError = .none

    var usingMarkdown: Bool = true
    private lazy var api = ChatAPI(apiKey: apiKey, messages: messages)
    var messageFeed = MessageFeed()
    
    init(sessionId:Int32) {
        selectSessionDetail(sessionId: sessionId)
        apiKey = UserDefaults.standard.string(forKey: API_KEY) ?? ""
    }

    
    
    // 新增apikey
    func insertApiKey(key: String){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            let sql1 = "INSERT INTO apikey (key) VALUES (?)"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")

            }
            sqlite3_bind_text(statement, 1, key, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error: \(errorMessage)")
            }else{
                print("插入成功")
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
    }
    
    
    // 新增sessionInfo
    func insertSessionInfo(name: String){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            let sql1 = "INSERT INTO sessioninfo (name) VALUES (?)"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            sqlite3_bind_text(statement, 1, name, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error: \(errorMessage)")
            }else{
                print("插入成功")
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
    }
    
    
    // 新增sessionDetail
    func insertSessionDetail(message: String, sessionId: Int32, isReceived: Int32){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var parentId: Int32 = 0
            var statement: OpaquePointer?
            let sql1 = "INSERT INTO sessiondetail (message, sessionInfoId, parentId, isReceived) VALUES (?, ?, ?, ?)"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")

            }
            var statement1: OpaquePointer?
            let sql2 = "SELECT MAX(id) FROM sessiondetail where sessionInfoId = ?;"
            if sqlite3_prepare_v2(db, sql2, -1, &statement1, nil) == SQLITE_OK {
                sqlite3_bind_int(statement1, 1, sessionId)
            }
            if sqlite3_step(statement1) == SQLITE_ROW {
                parentId = sqlite3_column_int(statement1, 0)
            }
            
            sqlite3_bind_text(statement, 1, message, -1, nil)
            sqlite3_bind_int(statement, 2, sessionId)
            sqlite3_bind_int(statement, 3, parentId)
            sqlite3_bind_int(statement, 4, isReceived)

            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error: \(errorMessage)")
            }else{
                print("插入成功")
            }
            sqlite3_finalize(statement)
            sqlite3_finalize(statement1)
            sqlite3_close(db)
        }
    }
    
    // 获取sessionDetail
    func selectSessionDetail(sessionId: Int32){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            let sql1 = "SELECT * FROM sessiondetail where sessionInfoId = ? ORDER BY parentId"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")

            }
            sqlite3_bind_int(statement, 1, sessionId)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                _ = sqlite3_column_int(statement, 0)
                let message = String(cString: sqlite3_column_text(statement, 1))
                _ = sqlite3_column_int(statement, 2)
                _ = sqlite3_column_int(statement, 3)
                let isReceived = sqlite3_column_int(statement, 4)
                let chat = ChatMessage(role: .user, message: message, isReceived: isReceived==1 ? true : false)
                messages.append(chat)
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
    }
    
   
    
    
    @discardableResult
    func sendMessage(_ message: String, sessionId: Int32) throws -> ChatMessage {
        if message.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ChatError.noQuestion
        }

        if apiKey.isEmpty {
            throw ChatError.noAPIKey
        }

        if isWorking {
            throw ChatError.isWorking
        }
        isWorking = true
        // 获取发送的消息
        let chat = ChatMessage(role: .user, message: message, isReceived: false)
        // 写入数据库
        insertSessionDetail(message: message, sessionId: sessionId, isReceived: 0)
        print(chat.message)
        messages.append(chat)
        lastMessageID = chat.id
        lastMessage = message
        request(question: message, sessionId: sessionId)
        return chat
    }

    func request(question: String, sessionId: Int32) {
        Task {
            do {
                let stream = try await self.api.sendMessage(question)
                let chat = await ChatMessage(role: .assistant, message: messageFeed.message, isReceived: true)
               
                DispatchQueue.main.async {
                    self.lastMessageID = chat.id
                    self.messages.append(chat)
                }
                for try await line in stream {
                    await messageFeed.append(line: line)
                    let newMessage = await messageFeed.message
                    DispatchQueue.main.async {
                        var last = self.messages.last!
                        last.message = newMessage
                        self.messages[self.messages.count - 1] = last
                        self.lastMessage = newMessage
                    }
                }
                // 写入数据库
                await insertSessionDetail(message: messageFeed.message, sessionId: sessionId, isReceived: 1)
                await messageFeed.reset()
                DispatchQueue.main.async {
                    self.isWorking = false
                }
            } catch {
                await messageFeed.reset()
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.chatErr = .request(message: error.localizedDescription)
                }
            }
        }
    }

    func cacheAPIKey(apiKey: String) {
//        apiKey = "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"
        self.api = ChatAPI(apiKey: apiKey, messages: messages)
        self.apiKey = apiKey
        UserDefaults.standard.set(apiKey, forKey: API_KEY)
    }
    
    func copyMessage(_ message : ChatMessage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.message, forType: .string)
    }
}

actor MessageFeed {
    var message: String = """
    """

    func append(line: String) {
        message += line
    }

    func reset() {
        message.removeAll()
    }
}
