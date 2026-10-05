import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var fullName = ""
    @State private var dateOfBirth = Date()
    @State private var gender: HEROSGender = .undisclosed
    @State private var showAvatarActions = false
    @State private var avatarPickerSource: AvatarPickerSource?
    @State private var showPhoneUpdate = false
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""

    var body: some View {
        Form {
            avatarSection

            Section("Thông tin cá nhân") {
                TextField("Họ và tên", text: $fullName)
                    .textContentType(.name)
                LabeledContent("Email", value: session.currentUser?.email ?? "")
                DatePicker("Ngày sinh", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                Picker("Giới tính", selection: $gender) {
                    ForEach(HEROSGender.allCases) { value in Text(value.title).tag(value) }
                }
            }

            Section("Số điện thoại") {
                LabeledContent("Số hiện tại", value: session.currentUser?.phoneNumber ?? "")
                Text("Số điện thoại được thay đổi bằng mã OTP gửi tới email tài khoản. Đây không phải xác minh sở hữu số điện thoại.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Thay đổi số điện thoại") { showPhoneUpdate = true }
            }

            if let error = session.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.footnote) }
            }

            Section {
                Button {
                    session.updateProfile(fullName: fullName, dateOfBirth: dateOfBirth, gender: gender)
                } label: {
                    HStack {
                        Spacer()
                        if session.isLoading { ProgressView().padding(.trailing, 6) }
                        Text("Lưu thay đổi").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(session.isLoading || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Hồ sơ cá nhân")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apply(session.currentUser)
            session.refreshProfile()
        }
        .onChange(of: session.currentUser) { _, user in apply(user) }
        .confirmationDialog("Ảnh đại diện", isPresented: $showAvatarActions) {
            if AvatarImagePicker.isAvailable(.camera) {
                Button("Chụp ảnh") { preparePicker(.camera) }
            }
            Button("Chọn từ thư viện") { preparePicker(.photoLibrary) }
            if session.currentUser?.avatarURL != nil {
                Button("Xóa ảnh đại diện", role: .destructive) { session.deleteAvatar() }
            }
            Button("Hủy", role: .cancel) {}
        }
        .sheet(item: $avatarPickerSource) { source in
            AvatarImagePicker(source: source) { result in
                avatarPickerSource = nil
                guard case .success(let data) = result else { return }
                session.updateAvatar(imageData: data)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhoneUpdate) {
            PhoneUpdateView().environmentObject(session)
        }
        .alert("Cần cấp quyền truy cập", isPresented: $showPermissionAlert) {
            Button("Mở Cài đặt") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Để sau", role: .cancel) {}
        } message: {
            Text(permissionMessage)
        }
    }

    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                Button { showAvatarActions = true } label: {
                    ZStack(alignment: .bottomTrailing) {
                        UserAvatarView(
                            urlString: session.currentUser?.avatarURL,
                            initials: session.currentUser?.initials ?? "HR",
                            size: 96
                        )
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Theme.Colors.primaryColor)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(session.isUpdatingAvatar)
                Spacer()
            }
            .padding(.vertical, 10)
        }
    }

    private func apply(_ user: HEROSAccount?) {
        guard let user else { return }
        fullName = user.fullName
        dateOfBirth = user.dateOfBirth
        gender = user.gender ?? .undisclosed
    }

    private func preparePicker(_ source: AvatarPickerSource) {
        Task {
            guard await AvatarMediaPermission.request(for: source) else {
                permissionMessage = source == .camera
                    ? "Hãy cho phép HEROS sử dụng Camera trong Cài đặt."
                    : "Hãy cho phép HEROS truy cập Ảnh trong Cài đặt."
                showPermissionAlert = true
                return
            }
            avatarPickerSource = source
        }
    }
}

private struct PhoneUpdateView: View {
    @EnvironmentObject private var session: AppSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var phone = "+84"
    @State private var otp = ""

    var body: some View {
        NavigationStack {
            Form {
                if session.phoneOTPChallenge == nil {
                    Section("Số điện thoại mới") {
                        TextField("+84901234567", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    Section {
                        Button("Gửi mã OTP qua email") { session.requestPhoneUpdateOTP(phone: phone) }
                            .disabled(session.isLoading)
                    }
                } else {
                    Section("Xác nhận qua email") {
                        Text("Nhập mã 6 chữ số đã gửi tới \(session.currentUser?.email ?? "email của bạn").")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TextField("Mã OTP", text: $otp)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .onChange(of: otp) { _, value in otp = String(value.filter(\.isNumber).prefix(6)) }
                    }
                    Section {
                        Button("Xác nhận thay đổi") { session.verifyPhoneUpdateOTP(otp) }
                            .disabled(session.isLoading || otp.count != 6)
                        Button("Gửi lại mã") {
                            otp = ""
                            session.requestPhoneUpdateOTP(phone: phone)
                        }
                        .disabled(session.isLoading)
                    }
                }

                if let error = session.errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Đổi số điện thoại")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
            }
            .onChange(of: session.currentUser?.phoneNumber) { oldValue, newValue in
                if oldValue != newValue, session.phoneOTPChallenge == nil { dismiss() }
            }
            .onDisappear { session.cancelPhoneUpdate() }
        }
    }
}
