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
                        Text(sessionInfo.name).frame(height: 20)
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
        .alert(R.Text.yourApiKey, isPresented: $showAlert, actions: {

            // Any view other than Button would be ignored
            Button(R.Text.done, action: {
                showAlert = false
                viewModel.cacheAPIKey()
            })
            Button(R.Text.cancel, role: .cancel, action: {
                showAlert = false
            })
        }){

            Text(R.Text.apiKeyDesc)
        }.toast(isPresenting: $showToast) {
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
