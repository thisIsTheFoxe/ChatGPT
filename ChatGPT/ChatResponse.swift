//
//  ChatResponse.swift
//  ChatGPT
//
//  Created by Henrik Storch on 10.12.22.
//

import Foundation

// MARK: - Welcome
struct ChatResponse: Codable {
    let message: ResponseMessage
    let conversationID: String
    let error: JSONNull?

    enum CodingKeys: String, CodingKey {
        case message
        case conversationID = "conversation_id"
        case error
    }
}

// MARK: - Message
struct ResponseMessage: Codable {
    let id, role: String
    let user, createTime, updateTime: JSONNull?
    let content: ResponseContent
    let endTurn: JSONNull?
    let weight: Int
    let metadata: Metadata
    let recipient: String

    enum CodingKeys: String, CodingKey {
        case id, role, user
        case createTime = "create_time"
        case updateTime = "update_time"
        case content
        case endTurn = "end_turn"
        case weight, metadata, recipient
    }
}

// MARK: - Content
struct ResponseContent: Codable {
    let contentType: String
    let parts: [String]

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
        case parts
    }
}

// MARK: - Metadata
struct Metadata: Codable {
}
