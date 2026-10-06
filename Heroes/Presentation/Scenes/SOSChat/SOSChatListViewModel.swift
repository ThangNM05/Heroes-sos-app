//
//  SOSChatListViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class SOSChatListViewModel: BaseViewModel {
    @Published private(set) var items: [SOSChatSummary] = []
    @Published var status: SOSChatStatus = .active
    @Published private(set) var hasMore = false
    @Published private(set) var messagePresence: [String: Bool] = [:]
    private let service: ISOSChatService
    private var nextCursor: String?
    private var generation = UUID()
    private var subscription: AnyCancellable?
    private weak var session: AppSessionStore?

    init(service: ISOSChatService, realtime: ISOSRealtimeClient) {
        self.service = service
        super.init()
        subscription = realtime.events.sink { [weak self] event in
            switch event {
            case .location, .recording: return
            default: break
            }
            guard let self, let session = self.session else { return }
            Task { await self.load(session: session, forceRefresh: true) }
        }
    }

    func load(session: AppSessionStore, reset: Bool = true, forceRefresh: Bool = false) async {
        self.session = session
        guard !isLoading else { return }
        if forceRefresh { service.invalidateCache() }
        if reset, items.isEmpty, let cached = service.cachedList(status: status, session: session) {
            items = cached.items
            hasMore = cached.nextCursor != nil
        }
        let epoch = generation
        isLoading = true
        defer { if epoch == generation { isLoading = false } }
        if reset { nextCursor = nil }
        do {
            var cursor = nextCursor
            var collected: [SOSChatSummary] = []
            repeat {
                let page = try await service.list(status: status, before: cursor, session: session)
                guard epoch == generation, session.isAuthenticated else { return }
                collected.append(contentsOf: page.items)
                guard page.nextCursor != cursor else { cursor = nil; break }
                cursor = page.nextCursor
            } while collected.isEmpty && cursor != nil
            if reset { items = collected }
            else {
                let existing = Set(items.map(\.id))
                items.append(contentsOf: collected.filter { !existing.contains($0.id) })
            }
            nextCursor = cursor
            hasMore = cursor != nil
            errorMessage = nil
            await loadMessagePresence(session: session, epoch: epoch)
        } catch {
            guard epoch == generation else { return }
            handleError(error)
            if let api = error as? APIError, [401, 403].contains(api.statusCode ?? 0) { items = [] }
        }
    }

    private func loadMessagePresence(session: AppSessionStore, epoch: UUID) async {
        let closed = items.filter { $0.status == .closed }
        for chat in closed where chat.lastMessageSequence == 0 { messagePresence[chat.id] = false }
        let candidates = closed.filter { $0.lastMessageSequence > 0 }
        // Bound parallelism so a long archive cannot flood the API.
        for start in stride(from: 0, to: candidates.count, by: 3) {
            guard epoch == generation, session.isAuthenticated else { return }
            await withTaskGroup(of: (String, Bool?).self) { group in
                for chat in candidates[start..<min(start + 3, candidates.count)] {
                    group.addTask { @MainActor in
                        let page = try? await self.service.messages(id: chat.id, before: nil, after: nil, session: session)
                        return (chat.id, page.map { $0.items.contains { $0.expiresAt > Date() } })
                    }
                }
                for await (id, presence) in group {
                    guard epoch == generation else { continue }
                    messagePresence[id] = presence
                }
            }
        }
    }

    func clear() {
        generation = UUID()
        items = []
        messagePresence = [:]
        nextCursor = nil
        hasMore = false
        isLoading = false
    }
}
