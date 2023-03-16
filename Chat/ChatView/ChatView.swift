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
    var body: some View {
        
        NavigationView{
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
                                    print(111111)
                                    sessionsModel.chatViewModels.removeValue(forKey: sessionInfo.id)
                                    print(sessionsModel.chatViewModels)
                                    sessionsModel.chatViewModels[sessionInfo.id]?.deleteSessionInfo(sessionId: sessionInfo.id)
                                    print(222222)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                Spacer()
                
            }.listStyle(SidebarListStyle())
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
            alert.informativeText = "请输入api_key"
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
                
                return Alert(title: Text("更新api_key成功！"))
            }else{
                return Alert(title: Text("取消成功"))
            }
            
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
