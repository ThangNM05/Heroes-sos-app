import SwiftUI

struct OwnerRecordingsView: View {
    @EnvironmentObject private var session: AppSessionStore
    @StateObject private var audioPlayer: ProtectedAudioPlayer
    @State private var records: [AudioRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var captured = UIScreen.main.isCaptured

    private let repository: ISOSAPIRepository

    init(repository: ISOSAPIRepository? = nil, audioPlayer: ProtectedAudioPlayer? = nil) {
        let resolvedRepository: ISOSAPIRepository = repository ?? AppDIContainer.shared.resolve()
        self.repository = resolvedRepository
        _audioPlayer = StateObject(wrappedValue: audioPlayer ?? AppDIContainer.shared.resolve())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()
                if isLoading && records.isEmpty {
                    ProgressView("Đang tải bản ghi...")
                } else if records.isEmpty {
                    ContentUnavailableView(
                        "Chưa có bản ghi",
                        systemImage: "waveform.slash",
                        description: Text(errorMessage ?? "Bản ghi SOS của bạn sẽ xuất hiện tại đây.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            privacyBanner
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(Theme.Fonts.medium.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.redColor)
                            }
                            ForEach(records) { record in recordCard(record) }
                        }
                        .padding(18)
                    }
                    .refreshable { await loadRecordings() }
                }
            }
            .navigationTitle("Bản ghi của tôi")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadRecordings() }
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                captured = UIScreen.main.isCaptured
                if captured { audioPlayer.stop() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appSessionDidInvalidate)) { _ in
                audioPlayer.clearAndStop()
                records = []
            }
        }
    }

    private var privacyBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill").foregroundColor(Theme.Colors.primaryColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Chỉ bạn có thể quản lý các bản ghi này").font(Theme.Fonts.bold.swiftUI(size: 13))
                Text("Tự động xóa sau 30 ngày. Người nhận chỉ được nghe trong thời gian sự cố.")
                    .font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
            }
        }
        .padding(14).background(Theme.Colors.softPink).cornerRadius(14)
    }

    private func recordCard(_ record: AudioRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    guard !captured, let sosId = record.sosId else { return }
                    audioPlayer.play(record: record, sosId: sosId, session: session)
                } label: {
                    ZStack {
                        Circle()
                            .fill(captured ? Color.gray : Theme.Colors.primaryColor)
                            .frame(width: 42, height: 42)
                        if audioPlayer.isLoading && audioPlayer.activeRecordingID == record.id {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: audioPlayer.activeRecordingID == record.id && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(record.sosId == nil)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title).font(Theme.Fonts.bold.swiftUI(size: 14))
                    Text(record.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                }
                Spacer()
                Text(record.formattedDuration).font(Theme.Fonts.semiBold.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
            }
            if captured {
                Label("Âm thanh đã tạm dừng vì thiết bị đang ghi/chia sẻ màn hình.", systemImage: "rectangle.slash")
                    .font(Theme.Fonts.medium.swiftUI(size: 11)).foregroundColor(Theme.Colors.redColor)
            } else {
                HStack {
                    Label("Lưu bảo mật trên thiết bị", systemImage: "lock.fill")
                    Spacer()
                    if let expiry = record.expiresAt { Text("Xóa \(expiry.formatted(date: .abbreviated, time: .omitted))") }
                }
                .font(Theme.Fonts.regular.swiftUI(size: 10)).foregroundColor(Theme.Colors.textSecondaryColor)
            }
        }
        .padding(16).background(Color.white).cornerRadius(16)
        .contextMenu {
            Button(role: .destructive) { delete(record) } label: { Label("Xóa bản ghi", systemImage: "trash") }
        }
    }

    @MainActor
    private func loadRecordings() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            records = try await session.performAuthenticatedRequest {
                try await repository.fetchOwnerRecordings(accessToken: $0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ record: AudioRecord) {
        guard let sosId = record.sosId else { return }
        Task {
            do {
                try await session.performAuthenticatedRequest {
                    try await repository.deleteRecording(sosId: sosId, recordingId: record.id, accessToken: $0)
                }
                if audioPlayer.activeRecordingID == record.id { audioPlayer.stop() }
                records.removeAll { $0.id == record.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
