//
//  SOSChatContractChecks.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

@main
struct SOSChatContractChecks {
    static func main() async throws {
        let now = Date()
        func message(_ id: String, sequence: Int, sender: String = "owner", client: String = "client",
                     chat: String = "chat", expiry: Date? = nil) -> SOSChatMessage {
            SOSChatMessage(id: id, chatId: chat, sosId: chat, clientMessageId: client, sequence: sequence,
                           sender: SOSChatSender(userId: sender, name: sender, avatarUrl: nil),
                           type: "text", text: "Tôi đang đến 👋", createdAt: now,
                           expiresAt: expiry ?? now.addingTimeInterval(600))
        }
        func check(_ condition: @autoclosure () -> Bool, _ label: String) {
            precondition(condition(), label)
            print("PASS: " + label)
        }

        let capped = SOSChatText.limited(String(repeating: "👋", count: 2001))
        check(capped.utf16.count == 2000 && capped.count == 1000, "Emoji input respects server-safe length without splitting characters")
        check(SOSChatText.normalized("  Tôi đang đến  ") == "Tôi đang đến", "Retry payload is trimmed once")
        check(SOSChatText.normalized(" \n\t ").isEmpty, "Whitespace-only messages are blocked")
        check(SOSChatText.limited(String(repeating: "a", count: 2001)).count == 2000, "ASCII input caps at 2000")

        let merged = SOSChatTimeline.merge(existing: [message("two", sequence: 2)],
            incoming: [message("one", sequence: 1), message("two", sequence: 2),
                       message("five", sequence: 5), message("expired", sequence: 3, expiry: now),
                       message("other", sequence: 4, chat: "other")], chatId: "chat", now: now)
        check(merged.map(\.sequence) == [1, 2, 5], "Duplicate, out-of-order, expired and other-chat events merge safely with sequence gaps")
        let pending = [SOSChatPendingMessage(id: "client", text: "Tôi đang đến", createdAt: now, state: .sending)]
        check(SOSChatTimeline.reconcile(pending: pending,
              confirmed: [message("contact", sequence: 1, sender: "contact")], senderId: "owner").count == 1,
              "Another sender's client UUID does not consume optimistic messages")
        check(SOSChatTimeline.reconcile(pending: pending,
              confirmed: [message("owner", sequence: 2)], senderId: "owner").isEmpty,
              "Socket before POST response reconciles optimistic message")

        var requested: [Int] = []
        let batch = try await SOSChatSynchronizer.catchUp(after: 0) { cursor in
            requested.append(cursor)
            if cursor == 0 {
                return SOSChatMessagePage(items: [message("one", sequence: 1)], hasMore: true,
                                          nextBeforeSequence: nil, nextAfterSequence: 1, lastSequence: 10)
            }
            return SOSChatMessagePage(items: [message("five", sequence: 5)], hasMore: false,
                                      nextBeforeSequence: nil, nextAfterSequence: nil, lastSequence: 10)
        }
        check(requested == [0, 1] && batch.lastSequence == 10 && batch.messages.count == 2,
              "Catch-up follows cursor, not the first page's lastSequence")
        do {
            _ = try await SOSChatSynchronizer.catchUp(after: 1) { _ in
                SOSChatMessagePage(items: [], hasMore: true, nextBeforeSequence: nil,
                                   nextAfterSequence: 1, lastSequence: 10)
            }
            preconditionFailure("Invalid cursor should fail")
        } catch SOSChatSynchronizationError.invalidCursor {
            print("PASS: Non-progressing cursor cannot advance watermark or loop forever")
        }
        do {
            _ = try await SOSChatSynchronizer.catchUp(after: 0) { cursor in
                if cursor == 0 {
                    return SOSChatMessagePage(items: [], hasMore: true, nextBeforeSequence: nil,
                                              nextAfterSequence: 5, lastSequence: 10)
                }
                throw URLError(.notConnectedToInternet)
            }
            preconditionFailure("Partial catch-up should fail")
        } catch {
            print("PASS: Failed second page does not return an advanced watermark")
        }

        // Matches production's closed-group response: optional avatars/address may be absent.
        let json = """
        {"id":"chat","sosId":"chat","sosCode":"SOS-TEST","title":"SOS - Thắng","ownerId":"owner",
        "ownerName":"Thắng","status":"closed","sosStatus":"resolved","memberCount":1,
        "createdAt":"2026-10-05T01:45:07.534Z","closedAt":"2026-10-05T01:45:21.498Z",
        "lastMessageSequence":0,"members":[{"userId":"owner","role":"owner","name":"Thắng",
        "joinedAt":"2026-10-05T01:45:07.534Z"}],"canSend":false,
        "currentLocation":{"type":"Point","coordinates":[108.2146575719664,16.040360634558407],
        "accuracy":6.86,"recordedAt":"2026-10-05T01:45:01.342Z"},"recordings":[]}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: value) else { throw URLError(.cannotDecodeContentData) }
            return date
        }
        let detail = try decoder.decode(SOSChatDetail.self, from: Data(json.utf8))
        check(!detail.canSend && detail.summary.status == .closed &&
              detail.currentLocation?.longitude == 108.2146575719664 &&
              detail.currentLocation?.latitude == 16.040360634558407,
              "Production closed group decodes with optional fields and longitude-first GeoJSON")
        print("All SOS chat contract checks passed.")
    }
}

