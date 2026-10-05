//
//  SOSChatSynchronizer.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

struct SOSChatSyncBatch {
    let messages: [SOSChatMessage]
    let lastSequence: Int
}

/// The watermark advances only after the complete REST catch-up has succeeded.
enum SOSChatSynchronizer {
    static func catchUp(
        after: Int,
        fetch: (Int) async throws -> SOSChatMessagePage
    ) async throws -> SOSChatSyncBatch {
        var cursor = after
        var collected: [SOSChatMessage] = []
        while true {
            try Task.checkCancellation()
            let page = try await fetch(cursor)
            collected.append(contentsOf: page.items)
            if !page.hasMore {
                return SOSChatSyncBatch(messages: collected, lastSequence: page.lastSequence)
            }
            guard let next = page.nextAfterSequence, next > cursor else {
                throw SOSChatSynchronizationError.invalidCursor
            }
            cursor = next
        }
    }
}

enum SOSChatSynchronizationError: LocalizedError {
    case invalidCursor
    var errorDescription: String? { "Không thể đồng bộ tin nhắn. Hãy thử tải lại." }
}

