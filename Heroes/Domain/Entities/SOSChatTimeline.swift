//
//  SOSChatTimeline.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

enum SOSChatTimeline {
    static func merge(
        existing: [SOSChatMessage],
        incoming: [SOSChatMessage],
        chatId: String,
        now: Date = Date()
    ) -> [SOSChatMessage] {
        var messages: [String: SOSChatMessage] = [:]
        for item in existing + incoming where item.chatId == chatId && item.expiresAt > now {
            messages[item.id] = item
        }
        return messages.values.sorted { $0.sequence < $1.sequence }
    }

    static func reconcile(
        pending: [SOSChatPendingMessage],
        confirmed: [SOSChatMessage],
        senderId: String?
    ) -> [SOSChatPendingMessage] {
        let confirmedIDs = Set(confirmed.filter { $0.sender.userId == senderId }.map(\.clientMessageId))
        return pending.filter { !confirmedIDs.contains($0.id) }
    }
}

