import AlertToast
import SwiftUI

struct ChatToolBarView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    var action: ((ChatMessage) -> Void)?

    @State private var question = """
    """

    @FocusState var isFocused

    private let height: CGFloat = 20
    
    public var sessionId: Int32
    
    var body: some View {
        ZStack {
            
            HStack {
                if #available(macOS 13.0, *) {
                    Spacer()
                    Spacer()
                    TextField("Message...", text: $question, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .textFieldStyle(.plain)
                        .frame(height: height)
                        .focused($isFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    Spacer()
                    Spacer()
                } else {
                    Spacer()
                    Spacer()
                    TextField("Message...", text: $question)
                        .textFieldStyle(.plain)
                        .frame(height: height)
                        .focused($isFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    Spacer()
                    Spacer()
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.2))
        .cornerRadius(30)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }

    func sendMessage() {
        do {
            let chat = try viewModel.sendMessage(question,sessionId: sessionId)
            question = ""
            action?(chat)
        } catch {
            if let er = error as? ChatError {
                self.viewModel.chatErr = er
            } else {
                self.viewModel.chatErr = .request(message: "\(error)")
            }
            NotificationCenter.default.post(name: Notification.Name("MyNotification"), object: nil)
        }
    }
}

