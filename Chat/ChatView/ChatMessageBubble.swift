import MarkdownUI
import Splash
import SwiftUI

struct ChatMessageBubble: View {
    var message: ChatMessage

    @EnvironmentObject var viewModel: ChatViewModel

    @Environment(\.colorScheme) private var colorScheme

    @State var size: CGSize = .init(width: 300, height: 300)
    
    public var sessionId: Int32

    private var theme: Splash.Theme {
        // NOTE: We are ignoring the Splash theme font
        switch colorScheme {
        case .dark:
            return .wwdc17(withFont: .init(size: 16))
        default:
            return .sunset(withFont: .init(size: 16))
        }
    }

    var body: some View {
        ZStack(alignment: message.isReceived ? .leading : .trailing) {
            GeometryReader { proxy in
                HStack {} // just an empty container to triggers the onAppear
                    .onAppear {
                        size = proxy.size
                    }
            }
            ZStack(alignment: .bottomTrailing) {
                getRenderView()
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 40)
                    .background(message.isReceived ? Color(R.Color.systemWhite.name) : .green.opacity(0.8))
                    .cornerRadius(10)
                    .textSelection(.enabled)

                Button(action: {
                    viewModel.copyMessage(message)
                }) {
                    Image(systemName: "square.filled.on.square")
                }
                .buttonStyle(.borderless)
                .padding([.trailing, .bottom])
            }
            .frame(maxWidth: size.width * 0.7, alignment: message.isReceived ? .leading : .trailing)
            .padding()
        }
        .id(message.id)
    }

    func getRenderView() -> some View {
        Group {
            if viewModel.usingMarkdown {
                Markdown(message.message)
                    .markdownCodeSyntaxHighlighter(.splash(theme: theme))
            } else {
                Text(message.message)
            }
        }
    }
}

//struct ChatMessageBubble_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatMessageBubble(message: .init(role: .user, message: #"""
//            ## Try GitHub Flavored Markdown
//
//            You can try **GitHub Flavored Markdown** here.  This dingus is powered
//            by [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI), a native
//            Markdown renderer for SwiftUI.
//
//            1. item one
//            1. item two
//               - sublist
//               - sublist
//        """#, isReceived: false))
//        .environmentObject(ChatViewModel())
//    }
//}
