import AlertToast
import Combine
import SwiftUI
import SQLite3

struct ChatView: View {
    
    @State var viewModel = ChatViewModel(sessionId: 1)
    @State var sessionsModel = ChatSessionModel()
    @State var showAlert: Bool = false
    @State private var showToast = false
    @State private var bindings: Set<AnyCancellable> = []
    @State var select: String? = ""
    @State private var inputText = ""
    @State private var showAddSession = false
    
    struct EditView: View {
        @Binding var sessionsModel1 : ChatSessionModel
        @State var viewModel = ChatViewModel(sessionId: 1)
        @Binding var showAddSession : Bool
        @State private var sessionName = ""
        @Binding var select: String?
        var body: some View {
            VStack {
                Image("AppIcon")
                TextField("输入会话名称", text: $sessionName)
                            .padding()
                            .cornerRadius(10)
                            .font(.system(size: 18))
                HStack {
                    Button(action: {
                        showAddSession = false
                    }) {
                        Text("取消")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        // 在这里执行创建会话的操作
                        let id = viewModel.insertSessionInfo(name: sessionName)
                        sessionsModel1.sessionInfoList.append(SessionDetail(id: id, name: sessionName))
                        showAddSession = false
                        select = sessionsModel1.sessionInfoList[0].name
                    }) {
                        Text("创建")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
            .frame(width: 300, height: 200)
        }
    }
    
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
                                if select == sessionInfo.name {
                                    Spacer()
                                    Button(action: {
                                        // 调用删除方法
                                        DispatchQueue.main.async {
                                            self.sessionsModel.sessionInfoList.removeAll(where: {$0.id == sessionInfo.id})
                                            self.sessionsModel.chatViewModels[sessionInfo.id]?.deleteSessionInfo(sessionId: sessionInfo.id)
                                            self.sessionsModel.chatViewModels.removeValue(forKey: sessionInfo.id)
                                            select = sessionsModel.sessionInfoList[0].name
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
                        showAddSession.toggle()
                    }) {
                        Text("添加会话")
                            .foregroundColor(.white)
                            .padding()
                    }.sheet(isPresented: $showAddSession) {
                      EditView(sessionsModel1: $sessionsModel, showAddSession: $showAddSession,select: $select)
                     }
                    
                    Button(action: {
                        
                    }) {
                        Text("检查更新")
                            .foregroundColor(.white)
                            .padding()
                    }
                    Text("Version 1.0.0")
                }.padding()
                
                    
            }
            
        }.toolbar{
            Button(action: {
                showAlert.toggle()
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
        }.alert(isPresented: $showAlert){
            let alert = NSAlert()
            alert.messageText = "MacGPT"
            alert.informativeText = "请输你的api_key"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.lineBreakMode = .byClipping
            alert.accessoryView = textField

            let result = alert.runModal()
            if result == .alertFirstButtonReturn {
                print(textField.stringValue)
                for session in sessionsModel.sessionInfoList{
                    self.sessionsModel.chatViewModels[session.id]?.cacheAPIKey(apiKey: textField.stringValue)
                }
                NSApp.stopModal()
                return Alert(title: Text("更新api_key成功！"))
            }else{
                NSApp.stopModal()
                return Alert(title: Text("取消成功"))
            }
            
        }
    }
    
    func alertView(infoText: String, type: Int) -> Alert{
        
        let alert = NSAlert()
        alert.messageText = "MacGPT"
        alert.informativeText = infoText
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.lineBreakMode = .byClipping
        alert.accessoryView = textField

        let result = alert.runModal()
        if result == .alertFirstButtonReturn {
            print(textField.stringValue)
            if(type == 100){
                for session in sessionsModel.sessionInfoList{
                    self.sessionsModel.chatViewModels[session.id]?.cacheAPIKey(apiKey: textField.stringValue)
                }
                
                return Alert(title: Text("更新api_key成功！"))
            }else if(type == 200){
                return Alert(title: Text("新增会话成功！"))
            }
            
        }else{
            return Alert(title: Text("取消成功"))
        }
        return Alert(title: Text("取消成功"))
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
