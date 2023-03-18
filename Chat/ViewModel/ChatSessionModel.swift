//
//  ChatSessionModel.swift
//  Chat
//
//  Created by kuls on 2023/3/15.
//

import Foundation
import AppKit
import SQLite3
import Combine

private let API_KEY = "api_key"

class ChatSessionModel: ObservableObject {
    @Published var sessionInfoList: [SessionDetail] = []
    @Published var chatViewModels: [Int32: ChatViewModel] = [:]
    @Published var apiKey: String = ""
    @Published var db: OpaquePointer?
    
    init() {
        apiKey = UserDefaults.standard.string(forKey: API_KEY) ?? ""
        initDatabase()
        selectSessionInfo()
        
        for sessioninfo in sessionInfoList{
            chatViewModels[sessioninfo.id] = ChatViewModel(sessionId: sessioninfo.id)
        }
    }
    
    func initDatabase() {
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            print("成功打开数据库")
            let createApiKeysTableSql = "CREATE TABLE IF NOT EXISTS apikeys (id INTEGER PRIMARY KEY AUTOINCREMENT,keyname TEXT);"
            let createSessionInfoTableSql = "CREATE TABLE IF NOT EXISTS sessioninfo (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT);"
            let createSessionDetailTableSql = "CREATE TABLE IF NOT EXISTS sessiondetail (id INTEGER PRIMARY KEY AUTOINCREMENT,message TEXT,sessionInfoId INTEGER, parentId INTEGER, isReceived INTEGER);"

            var createTableStatement: OpaquePointer?

            if sqlite3_prepare_v2(db, createApiKeysTableSql, -1, &createTableStatement, nil) == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("apikeys table created.")
                } else {
                    print("apikeys table could not be created.")
                }
            } else {
                print("CREATE TABLE statement could not be prepared.")
            }

            sqlite3_finalize(createTableStatement)

            if sqlite3_prepare_v2(db, createSessionInfoTableSql, -1, &createTableStatement, nil) == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("sessioninfo table created.")
                } else {
                    print("sessioninfo table could not be created.")
                }
            } else {
                print("CREATE TABLE statement could not be prepared.")
            }

            sqlite3_finalize(createTableStatement)

            if sqlite3_prepare_v2(db, createSessionDetailTableSql, -1, &createTableStatement, nil) == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("sessiondetail table created.")
                } else {
                    print("sessiondetail table could not be created.")
                }
            } else {
                print("CREATE TABLE statement could not be prepared.")
            }

            sqlite3_finalize(createTableStatement)
            sqlite3_close(db)
        }
    }
    
    
    // 查询sessionInfo
    func selectSessionInfo(){
        if sqlite3_open("gpt.db", &db) == SQLITE_OK {
            var statement: OpaquePointer?
            let sql1 = "SELECT * FROM sessioninfo"
            if sqlite3_prepare_v2(db, sql1, -1, &statement, nil) != SQLITE_OK {
                print("Error preparing statement")
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                let name = String(cString: sqlite3_column_text(statement, 1))
                sessionInfoList.append(SessionDetail(id: id, name: name))
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
    }
    
    func cacheAPIKey(apiKey: String) {
        
        // 先删除
        UserDefaults.standard.removeObject(forKey: API_KEY)
        // 再添加
        UserDefaults.standard.set(apiKey, forKey: API_KEY)
        // 每次更新apikey，直接把所有session都更新
        for sessioninfo in sessionInfoList{
            chatViewModels[sessioninfo.id]?.cacheAPIKey(apiKey: apiKey)
        }
    }
    
    
    
    
}



