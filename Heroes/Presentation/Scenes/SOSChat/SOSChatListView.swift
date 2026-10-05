//
//  SOSChatListView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatListView: View {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: SOSChatListViewModel

    init() {
        let container = AppDIContainer.shared
        _viewModel = StateObject(wrappedValue: SOSChatListViewModel(service: container.resolve(), realtime: container.resolve()))
    }

    var body: some View {
        List {
            if session.currentRole == .deviceOwner {
                Picker("Nhóm SOS", selection: $viewModel.status) {
                    Text("Đang hỗ trợ").tag(SOSChatStatus.active)
                    Text("Đã kết thúc").tag(SOSChatStatus.closed)
                }.pickerStyle(.segmented)
            }
            if let error = viewModel.errorMessage { Text(error).font(.footnote).foregroundStyle(.red) }
            ForEach(viewModel.items) { chat in
                NavigationLink { SOSChatView(chatId: chat.id) } label: {
                    SOSChatSummaryRow(chat: chat)
                }
            }
            if viewModel.hasMore {
                Button("Tải thêm nhóm") { Task { await viewModel.load(session: session, reset: false) } }
                    .disabled(viewModel.isLoading)
            }
            if viewModel.items.isEmpty && !viewModel.isLoading {
                ContentUnavailableView("Chưa có nhóm SOS", systemImage: "bubble.left.and.bubble.right",
                                       description: Text("Nhóm sẽ xuất hiện khi bạn tạo SOS hoặc xác nhận hỗ trợ."))
            }
        }
        .navigationTitle("Nhóm hỗ trợ SOS")
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.load(session: session) }
        .refreshable { await viewModel.load(session: session) }
        .onChange(of: viewModel.status) { _, _ in
            viewModel.clear()
            Task { await viewModel.load(session: session) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.load(session: session) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appSessionDidInvalidate)) { _ in viewModel.clear() }
        .onReceive(NotificationCenter.default.publisher(for: .emergencyRelationshipsDidChange)) { _ in
            viewModel.clear()
            Task { await viewModel.load(session: session) }
        }
    }
}
