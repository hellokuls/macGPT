import SwiftUI
import Combine


struct ChatSessionView: View {
    @State private var showToast = false
    @State private var bindings: Set<AnyCancellable> = []
    public var sessionId: Int32
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .trailing) {
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ChatMessageView(sessionId: sessionId)
                                .padding(.horizontal)
                                .environmentObject(viewModel)
                        }
                        .onChange(of: viewModel.lastMessage) { _ in
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(viewModel.lastMessageID, anchor: .bottom)
                                }
                            }
                        }
                    }.padding()

                    ChatToolBarView(sessionId: sessionId).environmentObject(viewModel)
                }
            }

        }
    }
   
}
