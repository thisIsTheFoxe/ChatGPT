//
//  OpenAI.swift
//  ChatGPT
//
//  Created by Henrik Storch on 10.12.22.
//

import Foundation

class OpenAI {
    static var jwt_session = "<#insert ChatGPT session JWT#>"
    static var jwt_access = "<#insert ChatGPT access JWT (optional)#>"
//    static let apiKey = "<#api key (unused)#>"
    
    var hasValidSessionToken: Bool { !OpenAI.jwt_session.isEmpty && !OpenAI.jwt_session.hasPrefix("<") }
    
    init() {
        if hasValidSessionToken {
            refresh(completion: { _ in })
        }
    }

    var conversationId: String?
    var parentId: String = UUID().uuidString.lowercased()
    
    func chat(message: ChatRequest, completion: @escaping (Result<ChatResponse, Error>) -> Void) {
        var req = URLRequest(url: URL(string: "https://chat.openai.com/backend-api/conversation")!)
        req.addValue("Bearer \(OpenAI.jwt_access)", forHTTPHeaderField: "Authorization")
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
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            print("callback")
            guard let data = data else {
                print(err, resp.debugDescription)
                return self.errorCompletion(resp: resp, err: err, completion: completion)
            }
            print("has data")
            
            guard let lines = String(data: data, encoding: .utf8)?.split(separator: "\n"),
                  lines.count > 3,
                  let jsonData = lines[lines.count - 3].trimmingPrefix("data: ").data(using: .utf8),
                  let response = try? JSONDecoder().decode(ChatResponse.self, from: jsonData) else {
                print(String(data: data, encoding: .utf8))
                return self.errorCompletion(resp: resp, err: err, completion: completion)
            }
            print("success", response.message.content)
            self.conversationId = response.conversationID
            self.parentId = response.message.id
            completion(.success(response))
        }
        .resume()
    }
    
    private func errorCompletion(resp: URLResponse?, err: Error?, completion: @escaping (Result<ChatResponse, Error>) -> Void) {
        if err == nil, let statusCode = (resp as? HTTPURLResponse)?.statusCode, let httpError = HTTPResponseError(rawValue: statusCode) {
            completion(.failure(httpError))
        } else if let err {
            completion(.failure(err))
        } else {
            completion(.failure(HTTPResponseError.unknown))
        }
    }
    
    func reset(completion: @escaping (UIMessage) -> Void) {
        conversationId = nil
        parentId = UUID().uuidString.lowercased()
        if hasValidSessionToken {
            refresh(completion: completion)
        }
    }
    
    func refresh(completion: @escaping (UIMessage) -> Void) {
        guard hasValidSessionToken else {
            return completion(UIMessage(id: UUID().uuidString, sender: .error, content: "No session token provided, could not update access token."))
        }
        var req = URLRequest(url: URL(string: "https://chat.openai.com/api/auth/session")!)
        req.addValue("Bearer \(OpenAI.jwt_session)", forHTTPHeaderField: "Authorization")
        req.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("__Secure-next-auth.session-token=\(OpenAI.jwt_session)", forHTTPHeaderField: "Cookie")
        req.httpShouldHandleCookies = true

        URLSession.shared.dataTask(with: req) { data, resp, err in
            guard let resp = resp as? HTTPURLResponse, let url = resp.url, let headers = resp.allHeaderFields as? [String: String] else {
                completion(UIMessage(id: UUID().uuidString, sender: .error, content: "No session Token"))
                return
            }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
            if let sessionToken = cookies.first(where: { $0.name == "__Secure-next-auth.session-token" })?.value {
                OpenAI.jwt_session = sessionToken
            }

            guard let data, let response = try? JSONDecoder().decode(OpenAIAuthResponse.self, from: data) else {
                completion(UIMessage(id: UUID().uuidString, sender: .error, content: "No access Token"))
                return
            }
            OpenAI.jwt_access = response.accessToken
        }.resume()
    }
}

struct OpenAIAuthResponse: Codable {
//    let user: User
    let expires, accessToken: String
}

// MARK: - User
struct User: Codable {
    let id, name, email: String
    let image, picture: String
    let groups: [String]
//    let features: [JSONAny]
}

enum HTTPResponseError: Int, LocalizedError {
    case unauthorized = 401, badResponse = -1, unknown = 0
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Error 401: Unauthorized"
        case .badResponse: return "Bad data."
        case .unknown: return "Unknown error."
        }
    }
}
