//
//  SOSChatViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class SOSChatViewModel: BaseViewModel {
    @Published private(set) var detail: SOSChatDetail?
    @Published private(set) var messages: [SOSChatMessage] = []
    @Published private(set) var pending: [SOSChatPendingMessage] = []
    @Published private(set) var accessRevoked = false
    @Published private(set) var acknowledgementRequired = false
    @Published private(set) var hasOlderMessages = false
    @Published private(set) var loadingOlder = false
    @Published private(set) var sendingLocked = false
    @Published private(set) var retryUntil: Date?
    @Published var draft = ""

    let chatId: String
    let audioPlayer: ProtectedAudioPlayer
    private let service: ISOSChatService
    private weak var session: AppSessionStore?
    private var subscriptions = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var sendTasks: [String: Task<Void, Never>] = [:]
    private var generation = UUID()
    private var lastSyncedSequence = 0
    private var nextBeforeSequence: Int?
    private var bufferedEvents: [SOSChatMessage] = []
    private var synchronizing = false
    private var refreshRequested = false

    var isOwner: Bool {
        if let ownerId = detail?.summary.ownerId { return ownerId == session?.currentUser?.id }
        return session?.currentRole == .deviceOwner
    }
    var canSend: Bool {
        detail?.canSend == true && !accessRevoked && !sendingLocked && !acknowledgementRequired
    }

    init(chatId: String, service: ISOSChatService, realtime: ISOSRealtimeClient, audioPlayer: ProtectedAudioPlayer) {
        self.chatId = chatId
        self.service = service
        self.audioPlayer = audioPlayer
        super.init()
        realtime.events.sink { [weak self] event in self?.receive(event) }.store(in: &subscriptions)
    }

    func start(session: AppSessionStore) {
        self.session = session
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                do { try await Task.sleep(for: .seconds(12)) } catch { break }
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        sendTasks.values.forEach { $0.cancel() }
        sendTasks = [:]
        generation = UUID()
        audioPlayer.clearAndStop()
        pending = pending.map {
            var item = $0
            if item.state == .sending { item.state = .failed }
            return item
        }
    }

    func refresh() async {
        guard let session, session.isAuthenticated, !accessRevoked else { return }
        if synchronizing { refreshRequested = true; return }
        synchronizing = true
        let epoch = generation
        defer {
            synchronizing = false
            if refreshRequested && !accessRevoked {
                refreshRequested = false
                Task { await self.refresh() }
            }
        }
        isLoading = detail == nil
        defer { isLoading = false }
        do {
            let fresh = try await service.detail(id: chatId, session: session)
            guard epoch == generation, !Task.isCancelled else { return }
            detail = fresh
            acknowledgementRequired = false
            if fresh.summary.status == .closed && !isOwner { revoke(); return }
            if fresh.summary.status == .closed {
                audioPlayer.clearAndStop()
                pending = []
                sendTasks.values.forEach { $0.cancel() }
            }
            var initialHistoryFloor: Int?
            if messages.isEmpty {
                let latest = try await service.messages(id: chatId, before: nil, after: nil, session: session)
                guard epoch == generation, !Task.isCancelled else { return }
                merge(latest.items)
                nextBeforeSequence = latest.nextBeforeSequence
                hasOlderMessages = latest.hasMore
                initialHistoryFloor = latest.items.first?.sequence
            }
            let batch = try await SOSChatSynchronizer.catchUp(after: lastSyncedSequence) { cursor in
                try await self.service.messages(id: self.chatId, before: nil, after: cursor, session: session)
            }
            guard epoch == generation, !Task.isCancelled else { return }
            // Older history remains accessible through beforeSequence instead of flooding the first screen.
            merge(batch.messages.filter { $0.sequence >= (initialHistoryFloor ?? 0) })
            lastSyncedSequence = batch.lastSequence
            let buffered = bufferedEvents
            bufferedEvents = []
            merge(buffered)
            if buffered.contains(where: { $0.sequence > batch.lastSequence }) { refreshRequested = true }
            messages.removeAll { $0.expiresAt <= Date() }
            errorMessage = nil
        } catch {
            guard epoch == generation, !Task.isCancelled else { return }
            process(error)
        }
    }

    func loadOlder() async {
        guard let session, let cursor = nextBeforeSequence, !loadingOlder, !accessRevoked else { return }
        let epoch = generation
        loadingOlder = true
        defer { loadingOlder = false }
        do {
            let page = try await service.messages(id: chatId, before: cursor, after: nil, session: session)
            guard epoch == generation else { return }
            merge(page.items)
            nextBeforeSequence = page.nextBeforeSequence
            hasOlderMessages = page.hasMore
        } catch { if epoch == generation { process(error) } }
    }

    func sendDraft() {
        let text = SOSChatText.normalized(draft)
        guard canSend, !text.isEmpty, (retryUntil ?? .distantPast) <= Date() else { return }
        let item = SOSChatPendingMessage(id: UUID().uuidString.lowercased(), text: text, createdAt: Date(), state: .sending)
        pending.append(item)
        draft = ""
        send(item)
    }

    func acknowledge(_ mode: SOSSupportMode) async {
        guard let session else { return }
        do {
            try await service.acknowledge(id: chatId, mode: mode, session: session)
            await refresh()
        } catch { process(error) }
    }

    func retry(_ item: SOSChatPendingMessage) {
        guard canSend, item.state == .failed, (retryUntil ?? .distantPast) <= Date() else { return }
        send(item)
    }

    private func send(_ item: SOSChatPendingMessage) {
        guard let session, sendTasks[item.id] == nil else { return }
        let epoch = generation
        setState(item.id, .sending)
        sendTasks[item.id] = Task {
            defer { sendTasks[item.id] = nil }
            for attempt in 0..<3 {
                do {
                    let message = try await service.send(id: chatId,
                        request: SOSChatMessageRequest(clientMessageId: item.id, text: item.text), session: session)
                    guard epoch == generation, !Task.isCancelled, !accessRevoked else { return }
                    merge([message])
                    return
                } catch {
                    guard epoch == generation, !Task.isCancelled else { return }
                    let api = error as? APIError
                    let retryable = api?.statusCode == nil || (api?.statusCode ?? 0) >= 500 || api?.statusCode == 408
                    if retryable && attempt < 2 {
                        do { try await Task.sleep(for: .seconds(Double(1 << attempt) + Double.random(in: 0...0.5))) }
                        catch { return }
                        continue
                    }
                    setState(item.id, retryable || api?.statusCode == 429 ? .failed : .blocked)
                    process(error)
                    return
                }
            }
        }
    }

    private func receive(_ event: SOSRealtimeEvent) {
        guard !accessRevoked else { return }
        switch event {
        case .chatMessage(let message) where message.chatId == chatId:
            guard detail?.summary.status == .active else { return }
            if synchronizing { bufferedEvents.append(message) }
            else {
                merge([message])
                Task { await self.refresh() }
            }
        case .chatClosed(let id) where id == chatId:
            sendingLocked = true
            audioPlayer.clearAndStop()
            if isOwner { Task { await self.refresh() } } else { revoke() }
        case .resolved(let id) where id == chatId,
             .cancelled(let id) where id == chatId:
            sendingLocked = true
            audioPlayer.clearAndStop()
            if isOwner { Task { await self.refresh() } } else { revoke() }
        case .ready:
            Task { await self.refresh() }
        case .chatMemberJoined(let id) where id == chatId:
            Task { await self.refresh() }
        case .location(let id) where id == chatId,
             .recording(let id) where id == chatId:
            Task { await self.refresh() }
        default: break
        }
    }

    private func merge(_ incoming: [SOSChatMessage]) {
        messages = SOSChatTimeline.merge(existing: messages, incoming: incoming, chatId: chatId)
        pending = SOSChatTimeline.reconcile(pending: pending, confirmed: messages, senderId: session?.currentUser?.id)
    }

    private func setState(_ id: String, _ state: SOSChatPendingMessage.State) {
        if let index = pending.firstIndex(where: { $0.id == id }) { pending[index].state = state }
    }

    private func process(_ error: Error) {
        guard let api = error as? APIError else { handleError(error); return }
        if api.serverCode == "SOS_CHAT_ACKNOWLEDGEMENT_REQUIRED" {
            acknowledgementRequired = true
            detail = nil
            messages = []
            audioPlayer.clearAndStop()
        } else if api.serverCode == "SOS_CHAT_CLOSED" {
            sendingLocked = true
            if isOwner { Task { await self.refresh() } } else { revoke() }
        } else if [403, 404, 401].contains(api.statusCode ?? 0) {
            revoke()
        } else if api.serverCode == "SOS_CHAT_MESSAGE_LIMIT_REACHED" {
            sendingLocked = true
        } else if api.statusCode == 429 {
            retryUntil = Date().addingTimeInterval(max(1, api.retryAfter ?? 60))
        }
        handleError(error)
    }

    func revoke() {
        accessRevoked = true
        stop()
        detail = nil
        messages = []
        pending = []
        bufferedEvents = []
        lastSyncedSequence = 0
        draft = ""
    }
}
