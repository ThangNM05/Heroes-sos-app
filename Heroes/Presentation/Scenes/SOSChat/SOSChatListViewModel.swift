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
    private let service: ISOSChatService
    private var nextCursor: String?
    private var generation = UUID()
    private var subscription: AnyCancellable?
    private weak var session: AppSessionStore?

    init(service: ISOSChatService, realtime: ISOSRealtimeClient) {
        self.service = service
        super.init()
        subscription = realtime.events.sink { [weak self] _ in
            guard let self, let session = self.session else { return }
            Task { await self.load(session: session) }
        }
    }

    func load(session: AppSessionStore, reset: Bool = true) async {
        self.session = session
        guard !isLoading else { return }
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
        } catch {
            guard epoch == generation else { return }
            handleError(error)
            if let api = error as? APIError, [401, 403].contains(api.statusCode ?? 0) { items = [] }
        }
    }

    func clear() {
        generation = UUID()
        items = []
        nextCursor = nil
        hasMore = false
        isLoading = false
    }
}
