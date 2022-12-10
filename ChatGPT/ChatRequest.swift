//
//  ChatRequest.swift
//  ChatGPT
//
//  Created by Henrik Storch on 10.12.22.
//

import Foundation

struct ChatRequest {
    var prompt: String
    var messageId: String
}


struct CahtRequestData: Codable {
    let action: String
    let messages: [Message]
    let parentMessageID, model: String
    let conversationID: String?
    
    enum CodingKeys: String, CodingKey {
        case action, messages
        case conversationID = "conversation_id"
        case parentMessageID = "parent_message_id"
        case model
    }
}

// MARK: - Message
struct Message: Codable {
    let id, role: String
    let content: Content
}

// MARK: - Content
struct Content: Codable {
    let contentType: String
    let parts: [String]

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
        case parts
    }
}
