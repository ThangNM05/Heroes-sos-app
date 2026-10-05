import SwiftUI
import MapKit

struct CommunityMapView: View {
    @EnvironmentObject private var session: AppSessionStore
    @StateObject private var viewModel: CommunityMapViewModel
    @State private var showingDetail = false
    @State private var showingSOSConfirmation = false
    @State private var screenIsCaptured = UIScreen.main.isCaptured

    init(viewModel: CommunityMapViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AppDIContainer.shared.resolve())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.alerts) { alert in
                    MapAnnotation(coordinate: alert.coordinate) {
                        Button {
                            viewModel.selectAlert(alert)
                            showingDetail = true
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().fill(Theme.Colors.redColor.opacity(0.2)).frame(width: 58, height: 58)
                                    UserAvatarView(
                                        urlString: alert.senderAvatarURL,
                                        initials: alert.senderInitials,
                                        size: 44
                                    )
                                    .overlay(Circle().stroke(Theme.Colors.redColor, lineWidth: 3))

                                    Text("SOS")
                                        .font(Theme.Fonts.extraBold.swiftUI(size: 8))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Theme.Colors.redColor)
                                        .clipShape(Capsule())
                                        .offset(y: 23)
                                }
                                Text(alert.senderName.components(separatedBy: " ").last ?? alert.senderName)
                                    .font(Theme.Fonts.bold.swiftUI(size: 10)).foregroundColor(Theme.Colors.textPrimaryColor)
                                    .padding(.horizontal, 7).padding(.vertical, 3).background(Color.white).cornerRadius(7)
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)

                if session.currentRole == .deviceOwner {
                    ownerControl
                } else {
                    incomingAlertsPanel
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        Image(systemName: "shield.fill").foregroundColor(Theme.Colors.primaryColor)
                        Text("HEROS").font(Theme.Fonts.extraBold.swiftUI(size: 17))
                    }
                }
            }
            .onAppear {
                session.activatePushNotifications()
                viewModel.loadAlerts(for: session.currentRole, currentUser: session.currentUser, session: session)
            }
            .onDisappear { viewModel.disconnectRealtime() }
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                screenIsCaptured = UIScreen.main.isCaptured
                if screenIsCaptured { viewModel.stopAudio() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .emergencyRelationshipsDidChange)) { _ in
                viewModel.clearSelection()
                showingDetail = false
                viewModel.stopAudioAndClearCache()
                viewModel.loadAlerts(for: session.currentRole, currentUser: session.currentUser, session: session)
            }
            .onReceive(NotificationCenter.default.publisher(for: .sosPushReceived)) { _ in
                viewModel.reloadFromServer()
            }
            .onReceive(NotificationCenter.default.publisher(for: .authenticationTokenDidChange)) { _ in
                viewModel.reconnectRealtime(session: session)
                viewModel.reloadFromServer()
            }
            .onReceive(NotificationCenter.default.publisher(for: .appSessionDidInvalidate)) { _ in
                viewModel.disconnectRealtime()
                viewModel.stopAudioAndClearCache()
                showingDetail = false
            }
            .sheet(isPresented: $showingDetail) {
                if let alert = viewModel.selectedAlert { alertDetail(alert) }
            }
            .confirmationDialog("Kích hoạt SOS?", isPresented: $showingSOSConfirmation, titleVisibility: .visible) {
                Button("Gửi SOS đến toàn bộ người thân", role: .destructive) {
                    viewModel.triggerSOS(currentUser: session.currentUser, session: session)
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("HEROS sẽ gửi vị trí và bắt đầu lưu bản ghi âm bảo mật.")
            }
        }
    }

    private var ownerControl: some View {
        VStack(spacing: 10) {
            if let alert = viewModel.alerts.first {
                HStack(spacing: 12) {
                    Circle().fill(Theme.Colors.redColor).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Đang phát tín hiệu SOS").font(Theme.Fonts.bold.swiftUI(size: 14))
                        Text("\(alert.respondersCount) người đã nhận hỗ trợ • \(alert.timeAgoString)")
                            .font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                    }
                    Spacer()
                    Button("Đã an toàn") { viewModel.resolveOwnSOS(session: session) }
                        .font(Theme.Fonts.bold.swiftUI(size: 12)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 9).background(Theme.Colors.greenColor).cornerRadius(10)
                }
                .padding(15).background(Color.white).cornerRadius(18).shadow(color: .black.opacity(0.08), radius: 10)
            } else {
                VStack(spacing: 10) {
                    Text("Bạn đang an toàn").font(Theme.Fonts.bold.swiftUI(size: 14))
                    Text("Nhấn giữ nút trên thiết bị hoặc dùng nút SOS khi cần trợ giúp.")
                        .font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                        .multilineTextAlignment(.center)
                    Button { showingSOSConfirmation = true } label: {
                        Text("SOS").font(Theme.Fonts.extraBold.swiftUI(size: 24)).foregroundColor(.white)
                            .frame(width: 84, height: 84).background(Theme.Colors.redColor).clipShape(Circle())
                            .shadow(color: Theme.Colors.redColor.opacity(0.35), radius: 12, y: 5)
                    }
                    .accessibilityLabel("Kích hoạt SOS")
                }
                .frame(maxWidth: .infinity).padding(18).background(Color.white).cornerRadius(22)
                .shadow(color: .black.opacity(0.08), radius: 10)
            }
        }
        .padding(.horizontal, 18).padding(.bottom, 10)
    }

    private var incomingAlertsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.alerts.isEmpty ? "Không có tín hiệu SOS" : "Người thân đang cần bạn")
                    .font(Theme.Fonts.bold.swiftUI(size: 16))
                Spacer()
                Text("\(viewModel.alerts.count) sự cố").font(Theme.Fonts.medium.swiftUI(size: 11)).foregroundColor(Theme.Colors.primaryColor)
            }

            if viewModel.alerts.isEmpty {
                Text("Các tín hiệu từ người thân đã kết nối sẽ xuất hiện tại đây.")
                    .font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
            } else if let alert = viewModel.alerts.first {
                Button {
                    viewModel.selectAlert(alert); showingDetail = true
                } label: {
                    HStack(spacing: 12) {
                        UserAvatarView(
                            urlString: alert.senderAvatarURL,
                            initials: alert.senderInitials,
                            size: 42
                        )
                        .overlay(Circle().stroke(Theme.Colors.redColor, lineWidth: 2))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(alert.senderName).font(Theme.Fonts.bold.swiftUI(size: 14)).foregroundColor(Theme.Colors.textPrimaryColor)
                            Text(alert.addressName).font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor).lineLimit(1)
                            Text("\(alert.respondersCount) người đã nhận hỗ trợ • \(alert.timeAgoString)")
                                .font(Theme.Fonts.semiBold.swiftUI(size: 10)).foregroundColor(Theme.Colors.primaryColor)
                        }
                        Spacer()
                        Image(systemName: "chevron.up").foregroundColor(Theme.Colors.textSecondaryColor)
                    }
                }
            }
        }
        .padding(18).background(Color.white).cornerRadius(22).shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private func alertDetail(_ alert: SOSAlert) -> some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray.opacity(0.25)).frame(width: 42, height: 5).padding(.top, 8)
            HStack(spacing: 12) {
                UserAvatarView(
                    urlString: alert.senderAvatarURL,
                    initials: alert.senderInitials,
                    size: 52
                )
                .overlay(Circle().stroke(Theme.Colors.primaryColor.opacity(0.25), lineWidth: 2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.senderName).font(Theme.Fonts.bold.swiftUI(size: 18))
                    Text("Đã gửi SOS \(alert.timeAgoString)").font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
                }
                Spacer()
            }

            detailRow(icon: "location.fill", title: "Vị trí hiện tại", value: alert.addressName, color: Theme.Colors.redColor)
            detailRow(icon: "figure.run", title: "Trạng thái hỗ trợ", value: "Hiện có \(alert.respondersCount) người đã nhận hỗ trợ", color: Theme.Colors.greenColor)

            if !alert.audioRecords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Bản ghi trực tiếp", systemImage: "waveform").font(Theme.Fonts.bold.swiftUI(size: 13))
                    ForEach(alert.audioRecords) { record in
                        HStack {
                            Button {
                                guard !screenIsCaptured else { return }
                                viewModel.playEvidenceAudio(record: record, session: session)
                            } label: {
                                Image(systemName: viewModel.activeAudioRecord?.id == record.id && viewModel.isPlayingAudio ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white).frame(width: 36, height: 36)
                                    .background(screenIsCaptured ? Color.gray : Theme.Colors.primaryColor).clipShape(Circle())
                            }
                            Text(record.title).font(Theme.Fonts.medium.swiftUI(size: 12))
                            Spacer()
                            Text(record.formattedDuration).font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                            Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(Theme.Colors.textSecondaryColor)
                        }
                    }
                    Text(screenIsCaptured ? "Âm thanh bị tắt khi thiết bị đang ghi/chia sẻ màn hình." : "Chỉ được nghe trực tuyến. Quyền truy cập sẽ bị thu hồi khi người gửi xác nhận an toàn.")
                        .font(Theme.Fonts.regular.swiftUI(size: 10)).foregroundColor(Theme.Colors.textSecondaryColor)
                }
                .padding(14).background(Color(Theme.Colors.bgColor)).cornerRadius(14)
            }

            Spacer()
            if session.currentRole == .trustedContact {
                HStack(spacing: 10) {
                    Button("Hỗ trợ từ xa") { viewModel.respondToAlert(mode: .remote, session: session); showingDetail = false }
                        .font(Theme.Fonts.bold.swiftUI(size: 13)).foregroundColor(Theme.Colors.primaryColor)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.Colors.softPink).cornerRadius(13)
                    Button("Tôi đang đến") { viewModel.respondToAlert(mode: .inPerson, session: session); showingDetail = false }
                        .font(Theme.Fonts.bold.swiftUI(size: 13)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.Colors.primaryColor).cornerRadius(13)
                }
            }
        }
        .padding(20).presentationDetents([.medium, .large])
    }

    private func detailRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Theme.Fonts.semiBold.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor)
                Text(value).font(Theme.Fonts.medium.swiftUI(size: 13))
            }
            Spacer()
        }
        .padding(14).background(Color(Theme.Colors.bgColor)).cornerRadius(14)
    }
}
