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
    @Published var prompt: String = ""
    var db: OpaquePointer?
    @Published var chatErr: ChatError = .none
    var usingMarkdown: Bool = true
    var messageFeed = MessageFeed()
    
    init(sessionId:Int32) {
        selectSessionDetail(sessionId: sessionId)
    }
    
    @discardableResult
    func sendMessage(_ message: String, sessionId: Int32) throws -> ChatMessage {
        if message.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ChatError.noQuestion
        }
        
        self.apiKey = selectAPIKey()
        
        if self.apiKey.isEmpty {
            throw ChatError.noAPIKey
        }

        if isWorking {
            throw ChatError.isWorking
        }
        isWorking = true
        // 获取发送的消息
        let chat = ChatMessage(role: .user, message: message, isReceived: false)
        insertSessionDetail(message: message, sessionId: sessionId, isReceived: 0)
        messages.append(chat)
        lastMessageID = chat.id
        lastMessage = message
        request(question: message, sessionId: sessionId, apikey: self.apiKey)
        return chat
    }

    func request(question: String, sessionId: Int32, apikey: String) {
        Task {
            do {
                let prompt = selectPrompt(sessionId: sessionId)
                var totalLength = 0
                
                for msg in messages{
                    totalLength += msg.message.count
                }
                if totalLength > 3500{
                    messages.removeFirst(3)
                }
                let api = ChatAPI(apiKey: apikey, systemPrompt: prompt, messages: self.messages)
                let stream = try await api.sendMessage(question)
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
                await insertSessionDetail(message: messageFeed.message, sessionId: sessionId, isReceived: 1)
                await messageFeed.reset()
                DispatchQueue.main.async {
                    self.isWorking = false
                }
            } catch {
                await messageFeed.reset()
              
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.chatErr = .request(message: "\(error)")
                    NotificationCenter.default.post(name: Notification.Name("MyNotification"), object: nil)
                }
            }
        }
    }
    
    func copyMessage(_ message : ChatMessage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.message, forType: .string)
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
    func insertSessionInfo(name: String, prompt: String) -> Int32{
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            
            var stmt: OpaquePointer?
            let queryString = "SELECT COUNT(*) FROM sessioninfo WHERE name = ?"
            defer{
                sqlite3_finalize(stmt)
                sqlite3_close(db)
            }
            if sqlite3_prepare_v2(db, queryString, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, name, -1, nil)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let count = sqlite3_column_int(stmt, 0)
                    if count > 0 {
                        return 0
                    }
                }
            }
            
        }
        
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            let sql1 = "INSERT INTO sessioninfo (name,prompt) VALUES (?,?)"
            defer{
                sqlite3_finalize(statement)
                sqlite3_close(db)
            }
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            sqlite3_bind_text(statement, 1, name, -1, nil)
            if prompt == ""{
                sqlite3_bind_text(statement, 2, "你是一个非常优秀的助手，能够帮我解答任何问题！", -1, nil)
            }else{
                sqlite3_bind_text(statement, 2, prompt, -1, nil)
            }
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error: \(errorMessage)")
            }else{
                if let rowId = Optional(sqlite3_last_insert_rowid(db)) {
                    return Int32(rowId)
                } else {
                    return 0
                }
            }
        }
        return 0
    }
    
    
    // 新增sessionDetail
    func insertSessionDetail(message: String, sessionId: Int32, isReceived: Int32){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var parentId: Int32 = 0
            var statement: OpaquePointer?
            var statement1: OpaquePointer?
            defer{
                sqlite3_finalize(statement)
                sqlite3_finalize(statement1)
                sqlite3_close(db)
            }
            let sql1 = "INSERT INTO sessiondetail (message, sessionInfoId, parentId, isReceived) VALUES (?, ?, ?, ?)"
            let sql2 = "SELECT MAX(id) FROM sessiondetail where sessionInfoId = ?;"
            
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            
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
            

        }
    }
    
    // 获取sessionDetail
    func selectSessionDetail(sessionId: Int32){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            defer{
                sqlite3_finalize(statement)
                sqlite3_close(db)
            }
            
            let sql1 = "SELECT * FROM (SELECT * FROM sessiondetail where sessionInfoId = ? ORDER BY parentId DESC LIMIT 10) sub ORDER BY parentId ASC;"
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
           
        }
    }
    
    // 删除sessioninfo
    func deleteSessionInfo(sessionId: Int32) {
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var deleteStatement1: OpaquePointer?
            var deleteStatement2: OpaquePointer?
            
            defer{
                sqlite3_finalize(deleteStatement1)
                sqlite3_finalize(deleteStatement2)
                sqlite3_close(db)
            }

            let deleteQuery1 = "DELETE FROM sessioninfo WHERE id = ?"
            let deleteQuery2 = "DELETE FROM sessiondetail WHERE sessionInfoId = ?"
            
            if sqlite3_prepare_v2(db, deleteQuery1, -1, &deleteStatement1, nil) == SQLITE_OK
                  && sqlite3_prepare_v2(db, deleteQuery2, -1, &deleteStatement2, nil) == SQLITE_OK {
                sqlite3_bind_int(deleteStatement1, 1, Int32(sessionId))
                sqlite3_bind_int(deleteStatement2, 1, Int32(sessionId))

                if sqlite3_step(deleteStatement1) == SQLITE_DONE {
                    print("Record deleted successfully.")
                } else {
                    print("Error deleting record.")
                }
                
                if sqlite3_step(deleteStatement2) == SQLITE_DONE {
                    print("Record deleted successfully.")
                } else {
                    print("Error deleting record.")
                }
            } else {
                print("Error preparing delete statement.")
            }
        }
        
    }
    
    // 从数据库中查询apikey
    func selectAPIKey() -> String{
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            
            defer{
                sqlite3_finalize(statement)
                sqlite3_close(db)
            }
            let sql1 = "SELECT * FROM apikeys"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                _ = sqlite3_column_int(statement, 0)
                let keyname = String(cString: sqlite3_column_text(statement, 1))
                self.apiKey = keyname
            }
           
        }
        return self.apiKey
    }
    
    // 从数据库中查询prompt
    func selectPrompt(sessionId: Int32) -> String{
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            
            defer{
                sqlite3_finalize(statement)
                sqlite3_close(db)
            }
            let sql1 = "SELECT prompt FROM sessioninfo where id = ?"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            sqlite3_bind_int(statement, 1, Int32(sessionId))
            while sqlite3_step(statement) == SQLITE_ROW {
                let prompt = String(cString: sqlite3_column_text(statement, 0))
                self.prompt = prompt
            }
           
        }
        return self.prompt
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
