import SwiftUI

struct SOSSettingsView: View {
    @EnvironmentObject private var session: AppSessionStore
    @StateObject private var viewModel: SOSSettingsViewModel
    @State private var showDeleteConfirmation = false
    @State private var showAccountDeletion = false
    @State private var showAvatarSourceOptions = false
    @State private var avatarPickerSource: AvatarPickerSource?
    @State private var showAvatarPermissionAlert = false
    @State private var avatarPermissionMessage = ""
    @State private var avatarSelectionError: String?

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

                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        Label("Xóa tài khoản", systemImage: "trash")
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
            .onAppear { viewModel.loadSettingsAndContacts(session: session, mode: .manage) }
            .confirmationDialog("Đổi ảnh đại diện", isPresented: $showAvatarSourceOptions) {
                if AvatarImagePicker.isAvailable(.camera) {
                    Button("Chụp ảnh") { prepareAvatarPicker(.camera) }
                }
                Button("Chọn từ thư viện") { prepareAvatarPicker(.photoLibrary) }
                Button("Hủy", role: .cancel) {}
            }
            .alert("Cần cấp quyền truy cập", isPresented: $showAvatarPermissionAlert) {
                Button("Mở Cài đặt") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                Button("Để sau", role: .cancel) {}
            } message: {
                Text(avatarPermissionMessage)
            }
            .alert("Xóa tài khoản HEROS?", isPresented: $showDeleteConfirmation) {
                Button("Hủy", role: .cancel) {}
                Button("Gửi mã xác nhận", role: .destructive) {
                    showAccountDeletion = true
                    session.requestAccountDeletionOTP()
                }
            } message: {
                Text("Dữ liệu và quyền truy cập của bạn sẽ bị thu hồi. Thao tác này không thể hoàn tác.")
            }
            .sheet(isPresented: $showAccountDeletion) {
                AccountDeletionView()
                    .environmentObject(session)
            }
            .sheet(item: $avatarPickerSource) { source in
                AvatarImagePicker(source: source) { result in
                    avatarPickerSource = nil
                    guard let result else { return }
                    switch result {
                    case .success(let data):
                        avatarSelectionError = nil
                        session.updateAvatar(imageData: data)
                    case .failure(let error):
                        avatarSelectionError = error.localizedDescription
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                Button {
                    showAvatarSourceOptions = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        UserAvatarView(
                            urlString: session.currentUser?.avatarURL,
                            initials: session.currentUser?.initials ?? "HR",
                            size: 56
                        )

                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Theme.Colors.primaryColor)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))

                        if session.isUpdatingAvatar {
                            Circle().fill(Color.black.opacity(0.4)).frame(width: 56, height: 56)
                            ProgressView().tint(.white)
                                .frame(width: 56, height: 56)
                        }
                    }
                }
                .disabled(session.isUpdatingAvatar)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.currentUser?.fullName ?? "HEROS User").font(Theme.Fonts.bold.swiftUI(size: 16))
                    Text(session.currentUser?.email ?? "").font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
                    Text(session.currentRole == .deviceOwner ? "Chủ thiết bị HEROS" : "Người thân được mời")
                        .font(Theme.Fonts.semiBold.swiftUI(size: 10)).foregroundColor(Theme.Colors.primaryColor)
                }
            }
            .padding(.vertical, 6)

            if let avatarError = avatarSelectionError ?? session.errorMessage {
                Text(avatarError)
                    .font(Theme.Fonts.medium.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.redColor)
            } else if session.isUpdatingAvatar {
                Text("Đang cập nhật ảnh đại diện...")
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }
        }
    }

    private func prepareAvatarPicker(_ source: AvatarPickerSource) {
        Task {
            avatarSelectionError = nil
            guard AvatarImagePicker.isAvailable(source) else {
                avatarSelectionError = "Thiết bị này không hỗ trợ nguồn ảnh đã chọn."
                return
            }

            let isAuthorized = await AvatarMediaPermission.request(for: source)
            guard isAuthorized else {
                avatarPermissionMessage = source == .camera
                    ? "Hãy cho phép HEROS sử dụng Camera trong Cài đặt để chụp ảnh đại diện."
                    : "Hãy cho phép HEROS truy cập Ảnh trong Cài đặt để chọn ảnh đại diện."
                showAvatarPermissionAlert = true
                return
            }

            avatarPickerSource = source
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

private struct AccountDeletionView: View {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var otp = ""
    @FocusState private var isOTPFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.Colors.redColor)

                Text("Xác nhận xóa tài khoản")
                    .font(Theme.Fonts.bold.swiftUI(size: 20))
                    .foregroundColor(Theme.Colors.textPrimaryColor)

                if session.accountDeletionChallenge == nil {
                    requestState
                } else {
                    verificationContent
                }

                Spacer()
            }
            .padding(24)
            .background(Color(Theme.Colors.bgColor).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                        .disabled(session.isLoading)
                }
            }
        }
        .interactiveDismissDisabled(session.isLoading)
        .onDisappear { session.cancelAccountDeletion() }
    }

    @ViewBuilder
    private var requestState: some View {
        if session.isLoading {
            ProgressView("Đang gửi mã xác nhận...")
                .tint(Theme.Colors.primaryColor)
        } else {
            if let error = session.errorMessage {
                deletionErrorText(error)
            }

            Button {
                session.requestAccountDeletionOTP()
            } label: {
                Text("Thử gửi lại mã")
                    .font(Theme.Fonts.bold.swiftUI(size: 15))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.primaryColor)
        }
    }

    private var verificationContent: some View {
        VStack(spacing: 18) {
            Text("Nhập mã 6 số đã gửi tới \(session.currentUser?.email ?? "email của bạn").")
                .font(Theme.Fonts.regular.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .multilineTextAlignment(.center)

            deletionOTPField

            if let error = session.errorMessage {
                deletionErrorText(error)
            }

            Button(role: .destructive) {
                isOTPFocused = false
                session.deleteAccount(otp: otp)
            } label: {
                HStack(spacing: 8) {
                    if session.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Xóa tài khoản vĩnh viễn")
                }
                .font(Theme.Fonts.bold.swiftUI(size: 15))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.redColor)
            .disabled(session.isLoading || otp.count != 6)

            Button("Gửi lại mã") {
                otp = ""
                session.requestAccountDeletionOTP()
                isOTPFocused = true
            }
            .font(Theme.Fonts.semiBold.swiftUI(size: 13))
            .foregroundColor(Theme.Colors.primaryColor)
            .disabled(session.isLoading)
        }
        .onAppear { isOTPFocused = true }
    }

    private var deletionOTPField: some View {
        let digits = Array(otp)

        return ZStack {
            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isOTPFocused)
                .opacity(0.01)
                .onChange(of: otp) { _, value in
                    let sanitized = String(value.filter(\.isNumber).prefix(6))
                    if sanitized != value { otp = sanitized }
                }

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Text(index < digits.count ? String(digits[index]) : "")
                        .font(Theme.Fonts.bold.swiftUI(size: 22))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index == min(digits.count, 5) && isOTPFocused
                                        ? Theme.Colors.primaryColor
                                        : Color(Theme.Colors.bgColor),
                                    lineWidth: 1.5
                                )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .allowsHitTesting(false)
        }
        .frame(height: 52)
        .contentShape(Rectangle())
        .onTapGesture { isOTPFocused = true }
    }

    private func deletionErrorText(_ message: String) -> some View {
        Text(message)
            .font(Theme.Fonts.medium.swiftUI(size: 12))
            .foregroundColor(Theme.Colors.redColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
