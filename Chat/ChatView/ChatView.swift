import AlertToast
import Combine
import SwiftUI
import SQLite3

struct ChatView: View {
    
    @State var viewModel = ChatViewModel(sessionId: 1)
    @ObservedObject var sessionsModel = ChatSessionModel()
    @State var showAlert: Bool = false
    @State private var showToast = false
    @State private var showAddSession = false
    @State private var bindings: Set<AnyCancellable> = []
    @State var select: String? = "macChatGPT"
    @State private var inputText = ""
    @State private var errMsg = ""
    
    var body: some View {
        NavigationView{
            VStack{
                List
                {
                    ForEach(sessionsModel.sessionInfoList)
                    {   sessionInfo in
                        NavigationLink(
                            destination: ChatSessionView(sessionId: sessionInfo.id, viewModel: sessionsModel.chatViewModels[sessionInfo.id] ?? viewModel),
                            tag: sessionInfo.name,
                            selection: $select)
                        {
                            
                            Text(sessionInfo.name)
                                .frame(height: 20)
                                .padding(1)
                            
                            if select == sessionInfo.name && self.sessionsModel.sessionInfoList.count > 1 {
                                Spacer()
                                Button(action: {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        self.sessionsModel.chatViewModels[sessionInfo.id]?.deleteSessionInfo(sessionId: sessionInfo.id)
                                        self.sessionsModel.chatViewModels.removeValue(forKey: sessionInfo.id)
                                        self.sessionsModel.sessionInfoList.removeAll(where: {$0.id == sessionInfo.id})
                                        select = nil
                                    }
                                }
                                }) {
                                    Image(systemName: "trash")
                                }.buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                    Spacer()
                }.listStyle(SidebarListStyle()).onDeleteCommand(perform: bindToast)
                
                VStack {
                    Button(action: {
                        DispatchQueue.main.async {
                            guard let mainWindow = NSApplication.shared.mainWindow else {
                                return
                            }
                            let alert = NSAlert()
                            alert.messageText = "新增会话"
                            alert.informativeText = "请输入会话名称"
                            alert.addButton(withTitle: "OK")
                            alert.addButton(withTitle: "Cancel")
                            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 150))

                            let textField1 = NSTextField(frame: NSRect(x: 0, y: 120, width: 200, height: 25))
                            textField1.placeholderString = "会话名称"
                            textField1.lineBreakMode = .byClipping
                            contentView.addSubview(textField1)
                            
                            let textField2 = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
                            textField2.placeholderString = "高阶玩法：你可以给chatGPT设定一个角色"
                            contentView.addSubview(textField2)
                            
                            alert.accessoryView = contentView
                            alert.beginSheetModal(for: mainWindow){ (response) in
                                if response == .alertFirstButtonReturn {
                                    // 在这里执行创建会话的操作
                                    let id = viewModel.insertSessionInfo(name: textField1.stringValue,prompt: textField2.stringValue)
                                    if id == 0 {
                                       self.errMsg = "添加失败"
                                       showToast = true
                                    }else{
                                        sessionsModel.sessionInfoList.append(SessionDetail(id: id, name: textField1.stringValue))
                                        sessionsModel.chatViewModels[id] = ChatViewModel(sessionId: id)
                                        showAddSession = false
                                        select = sessionsModel.sessionInfoList[sessionsModel.sessionInfoList.count - 1].name
                                        
                                    }
                                   
                                }
                            }
                        }
                    }) {
                        Text("添加会话")
                            .foregroundColor(.white)
                            .padding()
                    }
                    Button(action: {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            guard let mainWindow = NSApplication.shared.mainWindow else {
                                return
                            }
                            alert.messageText = "检查更新"
                            alert.informativeText = "请前往https://github.com/hellokuls/macGPT/releases下载最新版"
                            alert.addButton(withTitle: "OK")
                            alert.beginSheetModal(for: mainWindow){ (response) in
                            }
                        }
                    }) {
                        Text("检查更新")
                            .foregroundColor(.white)
                            .padding()
                    }
                }.padding()
                
                    
            }
            
        }.toolbar{
            Button(action: {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    guard let mainWindow = NSApplication.shared.mainWindow else {
                        return
                    }
                    alert.messageText = "系统设置"
                    alert.addButton(withTitle: "确定")
                    alert.addButton(withTitle: "取消")
                    
                    let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
                    
                    let textField = NSSecureTextField(frame: NSRect(x: 0, y: 40, width: 200, height: 24))
                    textField.lineBreakMode = .byClipping
                    textField.placeholderString = "请输入你的api_key"
                    accessoryView.addSubview(textField)

                    let radioButton = NSButton(radioButtonWithTitle: "选项 1", target: nil, action: nil)
                    radioButton.frame = NSRect(x: 0, y: 0, width: 200, height: 20)
                    accessoryView.addSubview(radioButton)
                
                    alert.accessoryView = accessoryView
                    alert.beginSheetModal(for: mainWindow){ (response) in
                        if response == .alertFirstButtonReturn {
                            // todo
                            if radioButton.state == .on {
                               
                            }
                        }
                    }
                }
            })
            {
                Image(systemName: "gear")
            }.padding([.top, .trailing], 10)
            
            Button(action: {
                let alert = NSAlert()
                guard let mainWindow = NSApplication.shared.mainWindow else {
                    return
                }
                alert.informativeText = "请输你的api_key"
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Cancel")
                
                let textField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
                textField.lineBreakMode = .byClipping
                alert.accessoryView = textField
                alert.beginSheetModal(for: mainWindow){ (response) in
                    if response == .alertFirstButtonReturn {
                        self.sessionsModel.cacheAPIKey(apiKey: textField.stringValue)
                    }
                }
         
            })
            {
                Image(systemName: "plus")
            }.padding([.top, .trailing], 10)
        }
        .navigationTitle(Text(select ?? ""))
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .hud, type: .error(Color.red), title: self.errMsg)}
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MyNotification"))){
            _ in
            DispatchQueue.main.async {
                bindToast()
            }
        }
    }
    
    func bindToast() {
        for session in sessionsModel.sessionInfoList{
            sessionsModel.chatViewModels[session.id]?.$chatErr
                .filter { $0 != .none }
                .receive(on: DispatchQueue.main)
                .sink { err in
                    self.errMsg = err.message
                    self.showToast = true
                }.store(in: &bindings)
        }
        
    }
   
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
