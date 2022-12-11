import SwiftUI

struct UIMessage: Identifiable, Equatable {
    enum MessageType: String { case user, chatgpt, error }
    var id: String
    var sender: MessageType
    var content: String
}

struct ContentView: View {
    @State var text = ""
    @State private var messages: [UIMessage] = []
    @State private var canSend = true
    @FocusState private var isFocused: Bool

    let api = OpenAI()
    
    var body: some View {
        NavigationStack {
            Spacer()
            MessageList(isFocused: $isFocused, messages: $messages)
            TextField("Type Message...", text: $text, onCommit: {
                sendMessage(inputText: text)
            })
            .focused($isFocused)
            .submitLabel(.send)
            .padding()
            Button("Send") {
                sendMessage(inputText: text)
            }.disabled(!canSend)
            .padding(.bottom)
            .navigationTitle("ChatGPT")
            .toolbar(content: {
                Button {
                    messages.removeAll()
                    text.removeAll()
                    api.reset { messages.append($0) }
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                }

                if !messages.isEmpty {
                    Button {
                        let allMsg = messages.map({ "\($0.sender.rawValue): \($0.content)" }).joined(separator: "\n")
                        let activityVC = UIActivityViewController(activityItems: [allMsg], applicationActivities: nil)
                        let allScenes = UIApplication.shared.connectedScenes
                        let scene = allScenes.first { $0.activationState == .foregroundActive }
                        
                        if let windowScene = scene as? UIWindowScene {
                            windowScene.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: nil)
                        }
                        
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            })
        }
    }
    
    func sendMessage(inputText: String) {
        guard canSend, !inputText.isEmpty else { return }
        canSend = false
        let request = ChatRequest(prompt: inputText, messageId: UUID().uuidString.lowercased())
        DispatchQueue.main.async {
            self.text = ""
            self.messages.append(UIMessage(id: request.messageId, sender: .user, content: request.prompt))
        }
        
        api.chat(message: request) { response, error in
            if let response = response {
                messages.append(UIMessage(id: response.message.id, sender: .chatgpt, content: response.message.content.parts.joined()))
            } else if let error = error {
                messages.append(UIMessage(id: UUID().uuidString, sender: .error, content: error.localizedDescription))
            }
            canSend = true
        }
    }
}

struct MessageView: View {
    var message: UIMessage
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            Text(message.content)
                .textSelection(.enabled)
                .padding(5)
                .background(message.sender == .user ? .gray : message.sender == .chatgpt ? .blue : .red)
                .cornerRadius(5)
                .padding(message.sender == .user ? .leading : .trailing, 24)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.content
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                }
            if message.sender != .user {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct MessageList: View {
    var isFocused: FocusState<Bool>.Binding
    @Binding var messages: [UIMessage]
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                    .onChange(of: messages) { _ in
                        guard !messages.isEmpty else { return }
                        withAnimation {
                            proxy.scrollTo(messages.last?.id)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            // dismiss keyboard
            isFocused.wrappedValue = false
        }
    }
}
