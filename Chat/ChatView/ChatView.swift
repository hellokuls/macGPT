import AlertToast
import Combine
import SwiftUI
import SQLite3

struct ChatView: View {
    
    @State var viewModel = ChatViewModel(sessionId: 1)
    @ObservedObject var sessionsModel = ChatSessionModel()
    @State var showAlert: Bool = false
    @State private var showToast = false
    @State private var bindings: Set<AnyCancellable> = []
    @State var select: String? = ""
    @State private var inputText = ""
    @State private var showAddSession = false
    
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
                            Group {
                                Text(sessionInfo.name)
                                    .frame(height: 20)
                                    .padding(1)
                                if select == sessionInfo.name && self.sessionsModel.sessionInfoList.count > 1 {
                                    Spacer()
                                    Button(action: {
                                        // 调用删除方法
                                        print(sessionsModel.sessionInfoList.count)
                                            DispatchQueue.main.async {
                                                self.sessionsModel.chatViewModels[sessionInfo.id]?.deleteSessionInfo(sessionId: sessionInfo.id)
                                                self.sessionsModel.chatViewModels.removeValue(forKey: sessionInfo.id)
                                                if select == sessionsModel.sessionInfoList[self.sessionsModel.sessionInfoList.count - 1].name {
                                                    self.sessionsModel.sessionInfoList.removeAll(where: {$0.id == sessionInfo.id})
                                                    select = sessionsModel.sessionInfoList[self.sessionsModel.sessionInfoList.count - 1].name
                                                }else if(select == sessionsModel.sessionInfoList[0].name){
                                                    self.sessionsModel.sessionInfoList.removeAll(where: {$0.id == sessionInfo.id})
                                                    select = sessionsModel.sessionInfoList[0].name
                                                }
                                            }
                                    }) {
                                        Image(systemName: "trash")
                                    }.buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        }
                    }
                    Spacer()
                }.listStyle(SidebarListStyle())

                // 添加一个按钮来切换列表的显示模式
                VStack {
                    Button(action: {
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
                        textField2.placeholderString = "高阶玩法：提示词...开发中"
                        contentView.addSubview(textField2)

                        alert.accessoryView = contentView
                        let result = alert.runModal()
                        if result == .alertFirstButtonReturn {
                            // 在这里执行创建会话的操作
                            let id = viewModel.insertSessionInfo(name: textField1.stringValue)
                            sessionsModel.sessionInfoList.append(SessionDetail(id: id, name: textField1.stringValue))
                            showAddSession = false
                            select = sessionsModel.sessionInfoList[sessionsModel.sessionInfoList.count - 1].name
                        }
                    }) {
                        Text("添加会话")
                            .foregroundColor(.white)
                            .padding()
                    }
                    Button(action: {
                        let alert = NSAlert()
                        alert.messageText = "检查更新"
                        alert.informativeText = "请前往https://github.com/hellokuls/macGPT/releases下载最新版"
                        alert.addButton(withTitle: "OK")
                        let result = alert.runModal()
                    }) {
                        Text("检查更新")
                            .foregroundColor(.white)
                            .padding()
                    }
                    Text("Version 1.0.2")
                }.padding()
                
                    
            }
            
        }.toolbar{
            Button(action: {
                let alert = NSAlert()
                
                alert.informativeText = "请输你的api_key"
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Cancel")
                
                let textField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
                textField.lineBreakMode = .byClipping
                alert.accessoryView = textField
                
                let result = alert.runModal()
                if result == .alertFirstButtonReturn {
                    self.sessionsModel.cacheAPIKey(apiKey: textField.stringValue)
                }
            })
            {
                Image(systemName: "plus")
            }.padding([.top, .trailing], 10)
        }.navigationTitle(Text(select ?? ""))
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
       .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .hud, type: .error(Color.red), title: viewModel.chatErr.message)
       }.onAppear {
           bindToast()
        }
    }
    
    func bindToast() {
        viewModel.$chatErr
            .filter { $0 != .none }
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.showToast = true
            }.store(in: &bindings)
    }
   
}


struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
