import SwiftUI

struct OwnerRecordingsView: View {
    @State private var records: [AudioRecord] = [
        AudioRecord(id: "OWNER-REC-001", title: "Sự cố tối 28/09", durationSeconds: 48, recordedAt: Date().addingTimeInterval(-172_800), fileURL: "secure-stream://OWNER-REC-001", isEvidence: true, expiresAt: Calendar.current.date(byAdding: .day, value: 28, to: Date()), isOwnerOnly: true),
        AudioRecord(id: "OWNER-REC-002", title: "Bản ghi thử thiết bị", durationSeconds: 16, recordedAt: Date().addingTimeInterval(-604_800), fileURL: "secure-stream://OWNER-REC-002", isEvidence: false, expiresAt: Calendar.current.date(byAdding: .day, value: 23, to: Date()), isOwnerOnly: true)
    ]
    @State private var playingID: String?
    @State private var captured = UIScreen.main.isCaptured

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()
                if records.isEmpty {
                    ContentUnavailableView("Chưa có bản ghi", systemImage: "waveform.slash", description: Text("Bản ghi SOS của bạn sẽ xuất hiện tại đây."))
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            privacyBanner
                            ForEach(records) { record in recordCard(record) }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Bản ghi của tôi")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                captured = UIScreen.main.isCaptured
                if captured { playingID = nil }
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
                    guard !captured else { return }
                    playingID = playingID == record.id ? nil : record.id
                } label: {
                    Image(systemName: playingID == record.id ? "pause.fill" : "play.fill")
                        .foregroundColor(.white).frame(width: 42, height: 42)
                        .background(captured ? Color.gray : Theme.Colors.primaryColor).clipShape(Circle())
                }
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
                    Label("Không cho phép tải xuống", systemImage: "lock.fill")
                    Spacer()
                    if let expiry = record.expiresAt { Text("Xóa \(expiry.formatted(date: .abbreviated, time: .omitted))") }
                }
                .font(Theme.Fonts.regular.swiftUI(size: 10)).foregroundColor(Theme.Colors.textSecondaryColor)
            }
        }
        .padding(16).background(Color.white).cornerRadius(16)
        .contextMenu {
            Button(role: .destructive) { records.removeAll { $0.id == record.id } } label: { Label("Xóa bản ghi", systemImage: "trash") }
        }
    }
}
