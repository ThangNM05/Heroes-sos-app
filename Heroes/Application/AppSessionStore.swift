import Foundation
import Combine

@MainActor
final class AppSessionStore: ObservableObject {
    @Published private(set) var currentUser: HEROSAccount?
    @Published var authStep: MockAuthStep = .signIn
    @Published var pendingAccount: HEROSAccount?
    @Published var errorMessage: String?

    private var credentials: [String: String] = [
        "owner@heros.vn": "123456",
        "contact@heros.vn": "123456"
    ]

    private var accounts: [String: HEROSAccount] = [
        "owner@heros.vn": HEROSAccount(
            id: "USER-OWNER-001",
            fullName: "Nguyễn Thị An",
            email: "owner@heros.vn",
            phoneNumber: "0901 234 567",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1996, month: 5, day: 12)) ?? Date(),
            role: .deviceOwner,
            isPhoneVerified: true,
            isEmailVerified: true,
            boundDeviceSerial: "HEROS-2026-001"
        ),
        "contact@heros.vn": HEROSAccount(
            id: "USER-CONTACT-001",
            fullName: "Trần Minh Huy",
            email: "contact@heros.vn",
            phoneNumber: "0912 345 678",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1994, month: 8, day: 20)) ?? Date(),
            role: .trustedContact,
            isPhoneVerified: true,
            isEmailVerified: true,
            boundDeviceSerial: nil
        )
    ]

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if let roleIndex = arguments.firstIndex(of: "-mock-role"), arguments.indices.contains(roleIndex + 1) {
            let role = arguments[roleIndex + 1]
            currentUser = accounts[role == "contact" ? "contact@heros.vn" : "owner@heros.vn"]
        }
    }

    var isAuthenticated: Bool { currentUser != nil }
    var currentRole: HEROSUserRole { currentUser?.role ?? .trustedContact }

    func signIn(email: String, password: String) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard credentials[normalizedEmail] == password, let account = accounts[normalizedEmail] else {
            errorMessage = MockAuthError.invalidCredentials.localizedDescription
            return
        }
        errorMessage = nil
        currentUser = account
    }

    func beginRegistration(
        fullName: String,
        email: String,
        phone: String,
        dateOfBirth: Date,
        role: HEROSUserRole,
        password: String
    ) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !fullName.isEmpty, !normalizedEmail.isEmpty, !phone.isEmpty, password.count >= 6 else {
            errorMessage = MockAuthError.missingInformation.localizedDescription
            return
        }
        guard accounts[normalizedEmail] == nil else {
            errorMessage = MockAuthError.duplicateEmail.localizedDescription
            return
        }

        credentials[normalizedEmail] = password
        pendingAccount = HEROSAccount(
            id: "USER-\(UUID().uuidString.prefix(8))",
            fullName: fullName,
            email: normalizedEmail,
            phoneNumber: phone,
            dateOfBirth: dateOfBirth,
            role: role,
            isPhoneVerified: false,
            isEmailVerified: true,
            boundDeviceSerial: nil
        )
        errorMessage = nil
        authStep = .verifyOTP
    }

    func verifyOTP(_ code: String) {
        guard code == "123456", var account = pendingAccount else {
            errorMessage = MockAuthError.invalidOTP.localizedDescription
            return
        }
        account.isPhoneVerified = true
        pendingAccount = account
        errorMessage = nil

        if account.role == .deviceOwner {
            authStep = .bindDevice
        } else {
            completeRegistration(account)
        }
    }

    func bindDevice(serial: String) {
        guard var account = pendingAccount else { return }
        let normalizedSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedSerial.isEmpty else {
            errorMessage = MockAuthError.missingInformation.localizedDescription
            return
        }
        let isBound = accounts.values.contains { $0.boundDeviceSerial == normalizedSerial }
        guard !isBound || normalizedSerial == "HEROS-DEMO-001" else {
            errorMessage = MockAuthError.deviceAlreadyBound.localizedDescription
            return
        }
        account.boundDeviceSerial = normalizedSerial
        completeRegistration(account)
    }

    func useDemoDevice() {
        bindDevice(serial: "HEROS-DEMO-001")
    }

    func signOut() {
        currentUser = nil
        pendingAccount = nil
        authStep = .signIn
        errorMessage = nil
    }

    func resetToSignIn() {
        pendingAccount = nil
        authStep = .signIn
        errorMessage = nil
    }

    private func completeRegistration(_ account: HEROSAccount) {
        accounts[account.email] = account
        pendingAccount = nil
        currentUser = account
        authStep = .signIn
    }
}
