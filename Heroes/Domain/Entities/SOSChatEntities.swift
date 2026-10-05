//
//  SOSChatEntities.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

enum SOSChatStatus: String, Codable, CaseIterable {
    case active, closed
}

struct SOSChatSummary: Identifiable, Decodable, Equatable {
    let id: String
    let sosId: String
    let sosCode: String?
    let title: String
    let ownerId: String
    let ownerName: String
    let ownerAvatarUrl: String?
    let status: SOSChatStatus
    let sosStatus: String
    let memberCount: Int
    let createdAt: Date
    let closedAt: Date?
    let lastMessageSequence: Int
}

struct SOSChatListPage: Decodable {
    let items: [SOSChatSummary]
    let nextCursor: String?
}

struct SOSChatMember: Identifiable, Decodable, Equatable {
    var id: String { userId }
    let userId: String
    let role: String
    let name: String
    let avatarUrl: String?
    let joinedAt: Date
    let supportMode: SOSSupportMode?
}

struct SOSChatLocation: Decodable, Equatable {
    let coordinates: [Double]
    let accuracy: Double?
    let recordedAt: Date
    let address: String?
    var longitude: Double { coordinates.first ?? 0 }
    var latitude: Double { coordinates.dropFirst().first ?? 0 }
}

struct SOSChatRecording: Identifiable, Decodable, Equatable {
    let id: String
    let mimeType: String
    let sizeBytes: Int
    let durationSeconds: Double
    let createdAt: Date
    let expiresAt: Date
    let playbackPath: String

    func audioRecord(sosId: String) -> AudioRecord {
        AudioRecord(id: id, title: "Bản ghi SOS", durationSeconds: Int(durationSeconds.rounded(.up)),
                    recordedAt: createdAt, fileURL: playbackPath, isEvidence: true,
                    expiresAt: expiresAt, isOwnerOnly: false, sosId: sosId, mimeType: mimeType)
    }
}

struct SOSChatDetail: Decodable {
    let summary: SOSChatSummary
    let canSend: Bool
    let members: [SOSChatMember]
    let currentLocation: SOSChatLocation?
    let currentAddress: String?
    let recordings: [SOSChatRecording]

    private enum CodingKeys: String, CodingKey {
        case canSend, members, currentLocation, currentAddress, recordings
    }
    init(from decoder: Decoder) throws {
        summary = try SOSChatSummary(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        canSend = try c.decode(Bool.self, forKey: .canSend)
        members = try c.decode([SOSChatMember].self, forKey: .members)
        currentLocation = try c.decodeIfPresent(SOSChatLocation.self, forKey: .currentLocation)
        currentAddress = try c.decodeIfPresent(String.self, forKey: .currentAddress)
        recordings = try c.decodeIfPresent([SOSChatRecording].self, forKey: .recordings) ?? []
    }
}

struct SOSChatSender: Decodable, Equatable {
    let userId: String
    let name: String
    let avatarUrl: String?
}

struct SOSChatMessage: Identifiable, Decodable, Equatable {
    let id: String
    let chatId: String
    let sosId: String
    let clientMessageId: String
    let sequence: Int
    let sender: SOSChatSender
    let type: String
    let text: String
    let createdAt: Date
    let expiresAt: Date
}

struct SOSChatMessagePage: Decodable {
    let items: [SOSChatMessage]
    let hasMore: Bool
    let nextBeforeSequence: Int?
    let nextAfterSequence: Int?
    let lastSequence: Int
}

struct SOSChatPendingMessage: Identifiable, Equatable {
    enum State: Equatable { case sending, failed, blocked }
    let id: String
    let text: String
    let createdAt: Date
    var state: State
}

/// One value is retained for every retry; sender identity is supplied by the server.
struct SOSChatMessageRequest: Encodable {
    let clientMessageId: String
    let text: String
}

enum SOSChatText {
    static let maximumLength = 2000
    static func limited(_ text: String) -> String {
        var result = ""
        var count = 0
        for character in text {
            let length = String(character).utf16.count
            guard count + length <= maximumLength else { break }
            result.append(character)
            count += length
        }
        return result
    }
    static func normalized(_ text: String) -> String {
        limited(text).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

