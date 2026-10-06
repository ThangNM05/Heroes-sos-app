//
//  SOSChatCacheChecks.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/6/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

// Standalone harness: compile with the real chat service/repository protocol and
// entities, excluding the app's session/API implementations. No production calls.
@MainActor
final class AppSessionStore {
    struct User { let id: String }
    var currentUser: User?
    var currentRole: HEROSUserRole = .deviceOwner
    var isAuthenticated: Bool { currentUser != nil }
    init(id: String) { currentUser = User(id: id) }
    func performAuthenticatedRequest<T>(_ operation: (String) async throws -> T) async throws -> T {
        guard let currentUser else { throw CheckError.unexpected }
        return try await operation(currentUser.id)
    }
}

protocol ISOSAPIRepository {
    func acknowledge(sosId: String, mode: SOSSupportMode, accessToken: String) async throws -> Bool
}

private enum CheckError: Error { case unexpected }

@MainActor
private final class Repository: ISOSChatRepository, ISOSAPIRepository {
    var listCalls = 0
    var historyCalls = 0
    var detailCalls = 0
    func list(status: SOSChatStatus, before: String?, accessToken: String) async throws -> SOSChatListPage {
        listCalls += 1
        try await Task.sleep(nanoseconds: 20_000_000)
        return SOSChatListPage(items: [], nextCursor: nil)
    }
    func messages(id: String, before: Int?, after: Int?, accessToken: String) async throws -> SOSChatMessagePage {
        historyCalls += 1
        try await Task.sleep(nanoseconds: 20_000_000)
        return SOSChatMessagePage(items: [], hasMore: false, nextBeforeSequence: nil,
                                  nextAfterSequence: nil, lastSequence: 0)
    }
    func detail(id: String, accessToken: String) async throws -> SOSChatDetail {
        detailCalls += 1
        throw CheckError.unexpected
    }
    func send(id: String, request: SOSChatMessageRequest, accessToken: String) async throws -> SOSChatMessage {
        throw CheckError.unexpected
    }
    func acknowledge(sosId: String, mode: SOSSupportMode, accessToken: String) async throws -> Bool { true }
}

@main
struct SOSChatCacheChecks {
    @MainActor
    static func main() async throws {
        func check(_ condition: @autoclosure () -> Bool, _ label: String) {
            precondition(condition(), label)
            print("PASS: " + label)
        }
        let repository = Repository()
        let service = SOSChatService(repository: repository, sosRepository: repository)
        let owner = AppSessionStore(id: "owner")
        let other = AppSessionStore(id: "other")

        async let first = service.list(status: .active, before: nil, session: owner)
        async let second = service.list(status: .active, before: nil, session: owner)
        _ = try await (first, second)
        check(repository.listCalls == 1, "Simultaneous list requests share one API call")
        _ = try await service.list(status: .active, before: nil, session: owner)
        check(repository.listCalls == 1, "Fresh list cache avoids repeated requests")
        check(service.cachedList(status: .active, session: other) == nil, "List cache is account-scoped")
        _ = try await service.list(status: .closed, before: nil, session: owner)
        check(repository.listCalls == 2, "Active and closed lists have separate keys")

        async let historyA = service.messages(id: "chat", before: nil, after: nil, session: owner)
        async let historyB = service.messages(id: "chat", before: nil, after: nil, session: owner)
        _ = try await (historyA, historyB)
        check(repository.historyCalls == 1, "Preload and screen history requests are coalesced")
        _ = try await service.messages(id: "chat", before: nil, after: 0, session: owner)
        _ = try await service.messages(id: "chat", before: 10, after: nil, session: owner)
        check(repository.historyCalls == 3, "Catch-up and pagination always use the API")
        _ = try await service.messages(id: "chat", before: nil, after: nil, session: other)
        check(repository.historyCalls == 4, "History is never reused across accounts")

        for _ in 0..<2 { _ = try? await service.detail(id: "chat", session: owner) }
        check(repository.detailCalls == 2, "Detail/access checks are never cached")
        service.invalidateCache()
        check(service.cachedList(status: .active, session: owner) == nil, "Invalidation clears cached lists")
        let pending = Task { try await service.list(status: .active, before: nil, session: owner) }
        try await Task.sleep(nanoseconds: 5_000_000)
        service.invalidateCache()
        _ = try? await pending.value
        check(service.cachedList(status: .active, session: owner) == nil, "Invalidated in-flight request cannot repopulate cache")
        await service.preload(session: owner)
        check(service.cachedList(status: .active, session: owner) != nil &&
              service.cachedList(status: .closed, session: owner) != nil, "Owner preload warms both list tabs")
        owner.currentUser = nil
        check(service.cachedList(status: .active, session: owner) == nil, "Logged-out session cannot read cache")
    }
}
