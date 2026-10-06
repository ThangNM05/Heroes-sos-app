import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var showingInviteConfirmation = false
    @State private var isSendingSOS = false

    var body: some View {
        Group {
            if session.currentRole == .deviceOwner { ownerTabs } else { trustedContactTabs }
        }
        .tint(Theme.Colors.primaryColor)
        .onPreferenceChange(AppLoadingPreferenceKey.self) { isSendingSOS = $0 }
        .disabled(isSendingSOS)
        .overlay {
            if isSendingSOS { AppLoadingView(message: "Đang gửi SOS…") }
        }
        .onAppear {
            showingInviteConfirmation = session.pendingInviteCode != nil
            session.activatePushNotifications()
        }
        .onChange(of: session.pendingInviteCode) { _, code in
            showingInviteConfirmation = code != nil
        }
        .sheet(isPresented: $showingInviteConfirmation) {
            PendingContactInviteView()
                .environmentObject(session)
        }
        .fullScreenCover(isPresented: Binding(
            get: { session.pendingSOSChatId != nil },
            set: { if !$0 { session.pendingSOSChatId = nil } }
        )) {
            if let id = session.pendingSOSChatId {
                NavigationStack {
                    SOSChatView(chatId: id)
                }
            }
        }
    }

    private var ownerTabs: some View {
        TabView {
            AppTabNavigationView { SOSDashboardView() }
                .tabItem { Label("SOS", systemImage: "sos.circle.fill") }
            AppTabNavigationView { CommunityMapView() }
                .tabItem { Label("Bản đồ", systemImage: "map.fill") }
            AppTabNavigationView { OwnerRecordingsView() }
                .tabItem { Label("Bản ghi", systemImage: "waveform") }
            AppTabNavigationView { DeviceManagementView() }
                .tabItem { Label("Thiết bị", systemImage: "sensor.tag.radiowaves.forward.fill") }
            AppTabNavigationView { SOSSettingsView() }
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
    }

    private var trustedContactTabs: some View {
        TabView {
            AppTabNavigationView { CommunityMapView() }
                .tabItem { Label("Bản đồ", systemImage: "map.fill") }
            AppTabNavigationView { EmergencyNetworkView(mode: .connections) }
                .tabItem { Label("Người thân", systemImage: "person.2.fill") }
            AppTabNavigationView { SOSSettingsView() }
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
    }
}

private struct PendingContactInviteView: View {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 46))
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Xác nhận lời mời")
                    .font(Theme.Fonts.bold.swiftUI(size: 20))
                Text("Chỉ chấp nhận nếu bạn nhận liên kết này từ người quen. Sau khi kết nối, bạn có thể nhận tín hiệu SOS của họ.")
                    .font(Theme.Fonts.regular.swiftUI(size: 13))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .multilineTextAlignment(.center)

                if session.currentRole != .trustedContact {
                    Text("Lời mời cần được mở bằng tài khoản Người thân.")
                        .font(Theme.Fonts.medium.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.amberColor)
                }
                if let message = session.inviteResultMessage {
                    Text(message)
                        .font(Theme.Fonts.medium.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.redColor)
                }

                Button {
                    session.acceptPendingInvite()
                } label: {
                    HStack {
                        if session.isAcceptingInvite { ProgressView().tint(.white) }
                        Text("Chấp nhận kết nối")
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.primaryColor)
                .disabled(session.isAcceptingInvite || session.currentRole != .trustedContact)

                Button("Xóa mã lời mời", role: .destructive) {
                    session.dismissPendingInvite()
                    dismiss()
                }
                .font(Theme.Fonts.medium.swiftUI(size: 12))
                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Để sau") { dismiss() }
                        .disabled(session.isAcceptingInvite)
                }
            }
        }
        .interactiveDismissDisabled(session.isAcceptingInvite)
    }
}

#Preview {
    MainTabView().environmentObject(AppSessionStore())
}
