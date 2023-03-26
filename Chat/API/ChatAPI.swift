import Foundation

class ChatAPI: @unchecked Sendable {
    let apiKey: String
    private let systemMessage: ChatMessage
    private var historyMessages = [ChatMessage]()
    private let urlSession = URLSession.shared
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()

    init(apiKey: String, systemPrompt: String, messages: [ChatMessage]) {
        self.apiKey = apiKey
        self.systemMessage = ChatMessage(role: .system, message: systemPrompt, isReceived: true)
        self.historyMessages = messages
    }
    
    func sendMessage(_ message: String, to endPoint: Endpoint = .chatCompletions) async throws -> AsyncThrowingStream<String, Error> {
        appendMessage(ChatMessage(role: .user, message: message, isReceived: false))
        let body = ChatRequest(messages: createMessages(from: message))
        let request = prepareRequest(endPoint, body: body)
        return try await makeRequest(request: request)
    }
    
    private func createMessages(from newMessage: String) -> [ChatMessage] {
        var messages = [systemMessage] + historyMessages + [ChatMessage(role: .user, message: newMessage, isReceived: false)]
        print("消息总数：",messages.contentCount)
//        if messages.contentCount > 25 {
//            _ = historyMessages.dropFirst()
//            messages = createMessages(from: newMessage)
//        }
        return messages
    }
    
    private func prepareRequest<BodyType: Encodable>(_ endpoint: Endpoint, body: BodyType) -> URLRequest {
        var urlComponents = URLComponents(url: URL(string: endpoint.baseURL())!, resolvingAgainstBaseURL: true)
        urlComponents?.path = endpoint.path
        var request = URLRequest(url: urlComponents!.url!)
        request.httpMethod = endpoint.method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print(apiKey)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(body) {
            request.httpBody = encoded
        }
        return request
    }
    
    private func makeRequest(request: URLRequest) async throws -> AsyncThrowingStream<String, Error> {
        let (result, response) = try await urlSession.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.request(message: "Invalid response")
        }
        print(httpResponse)
        guard 200...299 ~= httpResponse.statusCode else {
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            if let data = errorText.data(using: .utf8), let response = try? jsonDecoder.decode(ChatResponseError.self, from: data).error {
                errorText = "\n\(response.message)"
            }
            throw ChatError.request(message: "Bad Response: \(httpResponse.statusCode). \(errorText)")
        }

        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) { [weak self] in
                do {
                    var responseMessage = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? self?.jsonDecoder.decode(ChatResponse.self, from: data),
                           let text = response.choices.first?.delta.content
                        {
                            responseMessage += text
                            continuation.yield(text)
                        }
                    }
                    self?.appendMessage(ChatMessage(role: .assistant, message: responseMessage, isReceived: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func appendMessage(_ message:ChatMessage) {
        historyMessages.append(message)
    }
}

extension Array where Element == ChatMessage {
    var contentCount: Int { map { $0.message }.count }
}
