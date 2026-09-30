import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var session: AppSessionStore

    var body: some View {
        ZStack {
            Color(Theme.Colors.bgColor).ignoresSafeArea()

            switch session.authStep {
            case .signIn:
                SignInView()
            case .signUp:
                SignUpView()
            case .verifyOTP:
                OTPVerificationView()
            case .bindDevice:
                DeviceBindingView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.authStep)
    }
}

private struct AuthBrandHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image("img_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)

            Text(title)
                .font(Theme.Fonts.extraBold.swiftUI(size: 26))
                .foregroundColor(Theme.Colors.textPrimaryColor)

            Text(subtitle)
                .font(Theme.Fonts.regular.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

private struct SignInView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var email = "owner@heros.vn"
    @State private var password = "123456"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthBrandHeader(
                    title: "Chào mừng đến HEROS",
                    subtitle: "Kết nối nhanh với những người bạn tin tưởng khi cần hỗ trợ."
                )

                VStack(spacing: 14) {
                    authField("Email", text: $email, icon: "envelope.fill")
                    secureField("Mật khẩu", text: $password, icon: "lock.fill")

                    if let error = session.errorMessage {
                        errorText(error)
                    }

                    Button("Đăng nhập") {
                        session.signIn(email: email, password: password)
                    }
                    .buttonStyle(HEROSPrimaryButtonStyle())

                    Button("Tạo tài khoản mới") {
                        session.errorMessage = nil
                        session.authStep = .signUp
                    }
                    .font(Theme.Fonts.semiBold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.primaryColor)
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(20)

                VStack(spacing: 6) {
                    Text("Tài khoản demo")
                        .font(Theme.Fonts.bold.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                    Text("Chủ thiết bị: owner@heros.vn / 123456")
                    Text("Người thân: contact@heros.vn / 123456")
                }
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 36)
        }
    }
}

private struct SignUpView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var role: HEROSUserRole = .deviceOwner

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AuthBrandHeader(
                        title: "Tạo tài khoản",
                        subtitle: "Thông tin được dùng để xác minh và liên hệ khi có tình huống khẩn cấp."
                    )

                    VStack(spacing: 12) {
                        authField("Họ và tên", text: $fullName, icon: "person.fill")
                        authField("Email", text: $email, icon: "envelope.fill")
                        authField("Số điện thoại", text: $phone, icon: "phone.fill")
                        secureField("Mật khẩu (tối thiểu 6 ký tự)", text: $password, icon: "lock.fill")

                        DatePicker("Ngày sinh", selection: $dateOfBirth, displayedComponents: .date)
                            .font(Theme.Fonts.medium.swiftUI(size: 14))
                            .padding(14)
                            .background(Color(Theme.Colors.bgColor))
                            .cornerRadius(12)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bạn sử dụng HEROS với vai trò nào?")
                            .font(Theme.Fonts.bold.swiftUI(size: 14))

                        ForEach(HEROSUserRole.mvpRoles) { item in
                            Button {
                                role = item
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.iconName)
                                        .foregroundColor(role == item ? .white : Theme.Colors.primaryColor)
                                        .frame(width: 34, height: 34)
                                        .background(role == item ? Theme.Colors.primaryColor : Theme.Colors.softPink)
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item == .deviceOwner ? "Tôi có thiết bị HEROS" : "Tôi được người thân mời")
                                            .font(Theme.Fonts.bold.swiftUI(size: 13))
                                        Text(item == .deviceOwner ? "Có quyền kích hoạt SOS và quản lý bản ghi." : "Nhận tín hiệu và hỗ trợ người thân.")
                                            .font(Theme.Fonts.regular.swiftUI(size: 11))
                                            .foregroundColor(Theme.Colors.textSecondaryColor)
                                    }
                                    Spacer()
                                    Image(systemName: role == item ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(Theme.Colors.primaryColor)
                                }
                                .foregroundColor(Theme.Colors.textPrimaryColor)
                                .padding(12)
                                .background(role == item ? Theme.Colors.softPink : Color(Theme.Colors.bgColor))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)

                    if let error = session.errorMessage {
                        errorText(error)
                    }

                    Button("Tiếp tục xác minh") {
                        session.beginRegistration(
                            fullName: fullName,
                            email: email,
                            phone: phone,
                            dateOfBirth: dateOfBirth,
                            role: role,
                            password: password
                        )
                    }
                    .buttonStyle(HEROSPrimaryButtonStyle())
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đăng nhập") { session.resetToSignIn() }
                        .foregroundColor(Theme.Colors.primaryColor)
                }
            }
        }
    }
}

private struct OTPVerificationView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var code = "123456"

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            AuthBrandHeader(
                title: "Xác minh số điện thoại",
                subtitle: "Nhập mã 6 số đã gửi tới \(session.pendingAccount?.phoneNumber ?? "số điện thoại của bạn")."
            )

            TextField("Mã OTP", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(Theme.Fonts.bold.swiftUI(size: 24))
                .tracking(8)
                .padding(16)
                .background(Color.white)
                .cornerRadius(14)

            if let error = session.errorMessage { errorText(error) }

            Button("Xác minh") { session.verifyOTP(code) }
                .buttonStyle(HEROSPrimaryButtonStyle())

            Text("Mã OTP demo: 123456")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)
            Spacer()
        }
        .padding(24)
    }
}

private struct DeviceBindingView: View {
    @EnvironmentObject private var session: AppSessionStore
    @State private var serial = "HEROS-DEMO-001"

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            AuthBrandHeader(
                title: "Kết nối thiết bị",
                subtitle: "Mỗi thiết bị HEROS chỉ được liên kết với một tài khoản và một điện thoại."
            )

            VStack(spacing: 12) {
                authField("Serial thiết bị", text: $serial, icon: "number")

                Button {
                    session.useDemoDevice()
                } label: {
                    Label("Quét QR demo", systemImage: "qrcode.viewfinder")
                        .font(Theme.Fonts.semiBold.swiftUI(size: 14))
                        .foregroundColor(Theme.Colors.primaryColor)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)

            if let error = session.errorMessage { errorText(error) }

            Button("Liên kết và hoàn tất") { session.bindDevice(serial: serial) }
                .buttonStyle(HEROSPrimaryButtonStyle())
            Spacer()
        }
        .padding(24)
    }
}

private struct HEROSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.bold.swiftUI(size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.Colors.primaryColor.opacity(configuration.isPressed ? 0.75 : 1))
            .cornerRadius(14)
    }
}

private func authField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(Theme.Colors.primaryColor)
            .frame(width: 20)
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
    .padding(14)
    .background(Color(Theme.Colors.bgColor))
    .cornerRadius(12)
}

private func secureField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(Theme.Colors.primaryColor)
            .frame(width: 20)
        SecureField(placeholder, text: text)
    }
    .padding(14)
    .background(Color(Theme.Colors.bgColor))
    .cornerRadius(12)
}

private func errorText(_ message: String) -> some View {
    Label(message, systemImage: "exclamationmark.circle.fill")
        .font(Theme.Fonts.medium.swiftUI(size: 12))
        .foregroundColor(Theme.Colors.redColor)
        .frame(maxWidth: .infinity, alignment: .leading)
}
