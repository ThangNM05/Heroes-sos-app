import SwiftUI

struct SOSSettingsView: View {
    @EnvironmentObject private var session: AppSessionStore
    @StateObject private var viewModel: SOSSettingsViewModel

    init(viewModel: SOSSettingsViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SOSSettingsViewModel(sosService: AppDIContainer.shared.resolve()))
    }

    var body: some View {
        NavigationStack {
            List {
                profileSection

                if session.currentRole == .deviceOwner {
                    Section("An toàn") {
                        NavigationLink { EmergencyNetworkView(mode: .manage) } label: {
                            settingsRow(icon: "person.3.fill", title: "Mạng lưới khẩn cấp", subtitle: "\(viewModel.emergencyContacts.count)/10 người", color: Theme.Colors.primaryColor)
                        }
                        NavigationLink { OwnerRecordingsView() } label: {
                            settingsRow(icon: "waveform", title: "Quyền riêng tư bản ghi", subtitle: "Lưu tối đa 30 ngày", color: Theme.Colors.amberColor)
                        }
                    }
                }

                Section("Ứng dụng") {
                    settingsRow(icon: "bell.fill", title: "Thông báo", subtitle: "SOS và cập nhật an toàn", color: Theme.Colors.redColor)
                    settingsRow(icon: "lock.shield.fill", title: "Bảo mật", subtitle: "Thiết bị và phiên đăng nhập", color: Theme.Colors.blueColor)
                    settingsRow(icon: "questionmark.circle.fill", title: "Trợ giúp", subtitle: "Hướng dẫn sử dụng HEROS", color: Theme.Colors.greenColor)
                    settingsRow(icon: "doc.text.fill", title: "Điều khoản & quyền riêng tư", subtitle: nil, color: Theme.Colors.secondaryColor)
                }

                Section {
                    Button(role: .destructive) { session.signOut() } label: {
                        Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(Theme.Fonts.semiBold.swiftUI(size: 14))
                    }
                }

                Section {
                    Text("HEROS hỗ trợ kết nối người thân và không thay thế 113, 114 hoặc 115.")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(Theme.Colors.bgColor))
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadSettingsAndContacts() }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                Text(session.currentUser?.initials ?? "HR")
                    .font(Theme.Fonts.bold.swiftUI(size: 17)).foregroundColor(.white)
                    .frame(width: 50, height: 50).background(Theme.Colors.primaryColor).clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.currentUser?.fullName ?? "HEROS User").font(Theme.Fonts.bold.swiftUI(size: 16))
                    Text(session.currentUser?.email ?? "").font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
                    Text(session.currentRole == .deviceOwner ? "Chủ thiết bị HEROS" : "Người thân được mời")
                        .font(Theme.Fonts.semiBold.swiftUI(size: 10)).foregroundColor(Theme.Colors.primaryColor)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String?, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Fonts.medium.swiftUI(size: 14)).foregroundColor(Theme.Colors.textPrimaryColor)
                if let subtitle { Text(subtitle).font(Theme.Fonts.regular.swiftUI(size: 11)).foregroundColor(Theme.Colors.textSecondaryColor) }
            }
        }
        .padding(.vertical, 3)
    }
}
