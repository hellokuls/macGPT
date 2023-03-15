import SwiftUI

struct ChatMessageView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    var sessionId:Int32
    let columns = [GridItem(.flexible(minimum: 10))]

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(viewModel.messages,id: \.id) { message in
                ChatMessageBubble(message: message, sessionId: sessionId)
            }
        }
    }
}

//struct ChatMessageView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatMessageView(sessionId: <#Int32#>).environmentObject(ChatViewModel())
//    }
//}
