//
//  SOSRealtimeLifecycleModifier.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI
import UIKit

/// A single session owns the connection. Screens only subscribe to events.
struct SOSRealtimeLifecycleModifier: ViewModifier {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.scenePhase) private var scenePhase
    private let realtime: ISOSRealtimeClient = AppDIContainer.shared.resolve()
    private let chatService: ISOSChatService = AppDIContainer.shared.resolve()
    @ObservedObject private var pushRouter = SOSChatPushRouter.shared

    func body(content: Content) -> some View {
        content
            .task(id: session.currentUser?.id) {
                await chatService.preload(session: session)
            }
            .onReceive(realtime.events) { event in
                switch event {
                case .location, .recording: break
                default:
                    chatService.invalidateCache()
                    if event == .ready { Task { await chatService.preload(session: session) } }
                }
            }
            .onAppear { connect() }
            .onChange(of: session.activeAccessToken) { _, _ in connect() }
            .onReceive(NotificationCenter.default.publisher(for: .authenticationTokenDidChange)) { _ in connect() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    connect()
                    Task { await chatService.preload(session: session) }
                }
                else if phase == .background { realtime.disconnect() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appSessionDidInvalidate)) { _ in
                realtime.disconnect()
                chatService.invalidateCache()
                pushRouter.pendingChatId = nil
            }
            .onReceive(pushRouter.$pendingChatId) { _ in routePush() }
            .onReceive(NotificationCenter.default.publisher(for: .emergencyRelationshipsDidChange)) { _ in
                chatService.invalidateCache()
            }
    }

    private func connect() {
        guard scenePhase != .background else { realtime.disconnect(); return }
        if let token = session.activeAccessToken { realtime.connect(accessToken: token) }
        else { realtime.disconnect() }
        routePush()
    }

    private func routePush() {
        guard session.isAuthenticated, let id = pushRouter.pendingChatId, !id.isEmpty else { return }
        session.openSOSChat(id)
        pushRouter.pendingChatId = nil
    }
}
