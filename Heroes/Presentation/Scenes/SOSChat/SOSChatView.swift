//
//  SOSChatView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatView: View {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SOSChatViewModel
    @State private var showAcknowledge = false

    init(chatId: String) {
        let container = AppDIContainer.shared
        _viewModel = StateObject(wrappedValue: SOSChatViewModel(
            chatId: chatId, service: container.resolve(), realtime: container.resolve(),
            audioPlayer: ProtectedAudioPlayer(repository: container.resolve())))
    }

    var body: some View {
        VStack(spacing: 0) {
            SOSChatHeader(title: viewModel.detail?.summary.title ?? "Nhóm hỗ trợ SOS") { dismiss() }
            Group {
                if viewModel.accessRevoked {
                    ContentUnavailableView("Nhóm không còn khả dụng", systemImage: "lock",
                                           description: Text("Phiên hỗ trợ đã kết thúc hoặc quyền truy cập đã thay đổi."))
                } else if viewModel.acknowledgementRequired {
                    VStack(spacing: 18) {
                        ContentUnavailableView("Xác nhận hỗ trợ", systemImage: "person.2",
                                               description: Text("Bạn cần xác nhận hỗ trợ trước khi vào nhóm."))
                        Button("Tôi có thể hỗ trợ") { showAcknowledge = true }.buttonStyle(.borderedProminent)
                    }
                } else {
                    conversation
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.start(session: session) }
        .onDisappear { viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refresh() } }
            else if phase == .background { viewModel.audioPlayer.clearAndStop() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appSessionDidInvalidate)) { _ in viewModel.revoke(); dismiss() }
        .onReceive(NotificationCenter.default.publisher(for: .emergencyRelationshipsDidChange)) { _ in
            viewModel.audioPlayer.clearAndStop()
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            if UIScreen.main.isCaptured { viewModel.audioPlayer.clearAndStop() }
        }
        .confirmationDialog("Bạn có thể hỗ trợ không?", isPresented: $showAcknowledge) {
            Button("Tôi có thể hỗ trợ") { acknowledge(.remote) }
            Button("Tôi không thể hỗ trợ", role: .cancel) { dismiss() }
        }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            if let detail = viewModel.detail {
                DisclosureGroup("Vị trí, bản ghi và thành viên") {
                    SOSChatContextView(detail: detail, player: viewModel.audioPlayer) { recording in
                        guard !UIScreen.main.isCaptured else { return }
                        viewModel.audioPlayer.play(record: recording.audioRecord(sosId: viewModel.chatId),
                                                   sosId: viewModel.chatId, session: session)
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)
            }
            if let error = viewModel.errorMessage {
                HStack {
                    Text(error).font(.caption).foregroundStyle(.red)
                    Spacer()
                    Button("Tải lại") { Task { await viewModel.refresh() } }.font(.caption)
                }.padding(.horizontal)
            }
            messageHistory
            if viewModel.detail?.summary.status == .closed {
                Text("SOS đã kết thúc. Bạn có thể đọc lại lịch sử còn lưu.")
                    .font(.footnote).foregroundStyle(.secondary).padding()
            } else {
                SOSChatComposer(text: $viewModel.draft, canSend: viewModel.canSend,
                                retryUntil: viewModel.retryUntil, send: viewModel.sendDraft)
            }
        }
        .overlay { if viewModel.isLoading { ProgressView() } }
    }

    private var messageHistory: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.hasOlderMessages {
                        Button("Tải tin cũ hơn") { Task { await viewModel.loadOlder() } }
                            .disabled(viewModel.loadingOlder)
                    }
                    if viewModel.messages.isEmpty && viewModel.pending.isEmpty && !viewModel.isLoading {
                        Text("Chưa có tin nhắn. Trao đổi với nhóm để phối hợp hỗ trợ.")
                            .font(.footnote).foregroundStyle(.secondary).padding(.top, 40)
                    }
                    ForEach(viewModel.messages) { message in
                        SOSChatMessageRow(message: message, isOwn: message.sender.userId == session.currentUser?.id)
                            .id(message.id)
                    }
                    ForEach(viewModel.pending) { pending in
                        SOSChatPendingRow(message: pending) { viewModel.retry(pending) }
                    }
                    Color.clear.frame(height: 1).id("latest")
                }.padding()
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: viewModel.messages.last?.id) { _, _ in
                withAnimation { proxy.scrollTo("latest", anchor: .bottom) }
            }
            .onChange(of: viewModel.pending.count) { _, _ in
                withAnimation { proxy.scrollTo("latest", anchor: .bottom) }
            }
        }
    }

    private func acknowledge(_ mode: SOSSupportMode) {
        Task { await viewModel.acknowledge(mode) }
    }
}
