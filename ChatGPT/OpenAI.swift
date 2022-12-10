//
//  OpenAI.swift
//  ChatGPT
//
//  Created by Henrik Storch on 10.12.22.
//

import Foundation

class OpenAI {
    static let jwt = "<#insert JWT#>"
    var conversationId: String?
    var parentId: String = UUID().uuidString.lowercased()
    
    func chat(message: ChatRequest, completion: @escaping (ChatResponse?, Error?) -> Void) {
        var req = URLRequest(url: URL(string: "https://chat.openai.com/backend-api/conversation")!)
        req.addValue("Bearer \(OpenAI.jwt)", forHTTPHeaderField: "Authorization")
        req.addValue("https://chat.openai.com/chat", forHTTPHeaderField: "Referer")
        req.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        req.addValue("chat.openai.com", forHTTPHeaderField: "Host")
        req.addValue("", forHTTPHeaderField: "X-Openai-Assistant-App-Id")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let msg = CahtRequestData(
            action: "next",
            messages: [Message(
                id: message.messageId,
                role: "user",
                content: Content(contentType: "text", parts: [message.prompt]))],
            parentMessageID: parentId,
            model: "text-davinci-002-render",
            conversationID: conversationId)
        req.httpBody = try! JSONEncoder().encode(msg)
        req.httpMethod = "POST"
        
        print("req start")
        
        URLSession(configuration: .default).dataTask(with: req) { data, resp, err in
            print("callback")
            guard let data = data else {
                print(err, resp)
                completion(nil, err)
                return
            }
            print("has data")
            let lines = String(data: data, encoding: .utf8)!.split(separator: "\n")
            let jsonData = lines[lines.count-3].trimmingPrefix("data: ").data(using: .utf8)!
            
//            print("has json", String(data: jsonData, encoding: .utf8))
            guard let response = try? JSONDecoder().decode(ChatResponse.self, from: jsonData) else {
                print(String(data: data, encoding: .utf8))
                completion(nil, nil)
                return
            }
            print("success", response.message.content)
            self.conversationId = response.conversationID
            self.parentId = response.message.id
            completion(response, nil)
        }
        .resume()
    }
    
    func reset() {
        conversationId = nil
        parentId = UUID().uuidString.lowercased()
    }
}
