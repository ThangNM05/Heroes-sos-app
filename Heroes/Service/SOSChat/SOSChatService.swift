//
//  SOSChatService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation


@MainActor
final class SOSChatService: ISOSChatService {
    private let repository: ISOSChatRepository
    private let sosRepository: ISOSAPIRepository
    private var lists: [String: (Date, SOSChatListPage)] = [:]
    private var histories: [String: (Date, SOSChatMessagePage)] = [:]
    private var listTasks: [String: Task<SOSChatListPage, Error>] = [:]
    private var historyTasks: [String: Task<SOSChatMessagePage, Error>] = [:]
    private var cacheGeneration = UUID()

    // Account-scoped, short-lived RAM only. Never cache detail/access decisions.
    func cachedList(status: SOSChatStatus, session: AppSessionStore) -> SOSChatListPage? {
        guard let user = session.currentUser, session.isAuthenticated,
              let entry = lists[user.id + ":" + status.rawValue],
              Date().timeIntervalSince(entry.0) < 20 else { return nil }
        return entry.1
    }

    func invalidateCache() {
        cacheGeneration = UUID()
        listTasks.values.forEach { $0.cancel() }
        historyTasks.values.forEach { $0.cancel() }
        listTasks.removeAll()
        historyTasks.removeAll()
        lists.removeAll()
        histories.removeAll()
    }

    func preload(session: AppSessionStore) async {
        guard session.isAuthenticated else { return }
        let epoch = cacheGeneration
        let statuses: [SOSChatStatus] = session.currentRole == .deviceOwner ? [.active, .closed] : [.active]
        await withTaskGroup(of: Void.self) { group in
            for status in statuses {
                group.addTask { @MainActor in
                    guard let page = try? await self.list(status: status, before: nil, session: session),
                          epoch == self.cacheGeneration else { return }
                    // Warm only a few recent histories; opening still revalidates access.
                    for chat in page.items.prefix(3) where chat.lastMessageSequence > 0 {
                        guard !Task.isCancelled, epoch == self.cacheGeneration else { return }
                        _ = try? await self.messages(id: chat.id, before: nil, after: nil, session: session)
                    }
                }
            }
        }
    }
    init(repository: ISOSChatRepository, sosRepository: ISOSAPIRepository) {
        self.repository = repository
        self.sosRepository = sosRepository
    }

    func acknowledge(id: String, mode: SOSSupportMode, session: AppSessionStore) async throws {
        _ = try await session.performAuthenticatedRequest {
            try await self.sosRepository.acknowledge(sosId: id, mode: mode, accessToken: $0)
        }
    }

    func list(status: SOSChatStatus, before: String?, session: AppSessionStore) async throws -> SOSChatListPage {
        guard before == nil, let user = session.currentUser else {
            return try await session.performAuthenticatedRequest {
                try await self.repository.list(status: status, before: before, accessToken: $0)
            }
        }
        if let cached = cachedList(status: status, session: session) { return cached }
        let key = user.id + ":" + status.rawValue
        if let task = listTasks[key] { return try await task.value }
        let epoch = cacheGeneration
        let task = Task { try await session.performAuthenticatedRequest {
            try await self.repository.list(status: status, before: nil, accessToken: $0)
        } }
        listTasks[key] = task
        defer { if epoch == cacheGeneration { listTasks[key] = nil } }
        let page = try await task.value
        if epoch == cacheGeneration, session.isAuthenticated { lists[key] = (Date(), page) }
        return page
    }
    func detail(id: String, session: AppSessionStore) async throws -> SOSChatDetail {
        try await session.performAuthenticatedRequest { try await self.repository.detail(id: id, accessToken: $0) }
    }
    func messages(id: String, before: Int?, after: Int?, session: AppSessionStore) async throws -> SOSChatMessagePage {
        guard before == nil, after == nil, let user = session.currentUser else {
            return try await session.performAuthenticatedRequest {
                try await self.repository.messages(id: id, before: before, after: after, accessToken: $0)
            }
        }
        let key = user.id + ":" + id
        if let cached = histories[key], Date().timeIntervalSince(cached.0) < 15 { return cached.1 }
        if let task = historyTasks[key] { return try await task.value }
        let epoch = cacheGeneration
        let task = Task { try await session.performAuthenticatedRequest {
            try await self.repository.messages(id: id, before: nil, after: nil, accessToken: $0)
        } }
        historyTasks[key] = task
        defer { if epoch == cacheGeneration { historyTasks[key] = nil } }
        let page = try await task.value
        if epoch == cacheGeneration, session.isAuthenticated {
            if histories.count >= 40, let oldest = histories.min(by: { $0.value.0 < $1.value.0 })?.key {
                histories[oldest] = nil
            }
            histories[key] = (Date(), page)
        }
        return page
    }
    func send(id: String, request: SOSChatMessageRequest, session: AppSessionStore) async throws -> SOSChatMessage {
        try await session.performAuthenticatedRequest {
            try await self.repository.send(id: id, request: request, accessToken: $0)
        }
    }
}
