import Foundation
import Combine
import FirebaseCore
import FirebaseMessaging

@MainActor
final class AppSessionStore: ObservableObject {
    @Published private(set) var currentUser: HEROSAccount?
    @Published private(set) var isLoading = false
    @Published var authStep: AuthStep = .signIn
    @Published private(set) var pendingRegistration: PendingRegistration?
    @Published private(set) var pendingEmail: String?
    @Published private(set) var pendingPurpose: EmailOTPPurpose?
    @Published private(set) var otpChallenge: EmailOTPChallenge?
    @Published private(set) var accountDeletionChallenge: AccountDeletionChallenge?
    @Published private(set) var isUpdatingAvatar = false
    @Published private(set) var pendingInviteCode: String?
    @Published private(set) var isAcceptingInvite = false
    @Published var inviteResultMessage: String?
    @Published var errorMessage: String?

    private let authService: IAuthService
    private let sessionStore: AuthSessionStoring
    private let installationIDProvider: InstallationIDProviding
    private let emergencyContactsRepository: IEmergencyContactsRepository
    private let pendingInviteStore: PendingInviteCodeStoring
    private let pushDeviceRepository: IPushDeviceRepository
    private var session: AuthSession?
    private var pushToken: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: IAuthService? = nil,
        sessionStore: AuthSessionStoring? = nil,
        installationIDProvider: InstallationIDProviding? = nil,
        emergencyContactsRepository: IEmergencyContactsRepository? = nil,
        pendingInviteStore: PendingInviteCodeStoring? = nil,
        pushDeviceRepository: IPushDeviceRepository? = nil
    ) {
        self.authService = authService ?? AuthService(repository: AuthRepository(networkClient: NetworkClient()))
        self.sessionStore = sessionStore ?? KeychainAuthSessionStore()
        self.installationIDProvider = installationIDProvider ?? InstallationIDProvider()
        self.emergencyContactsRepository = emergencyContactsRepository
            ?? EmergencyContactsRepository(networkClient: NetworkClient())
        self.pendingInviteStore = pendingInviteStore ?? KeychainPendingInviteCodeStore()
        self.pushDeviceRepository = pushDeviceRepository
            ?? PushDeviceRepository(networkClient: NetworkClient())
        self.pendingInviteCode = try? self.pendingInviteStore.load()

        if let savedSession = try? self.sessionStore.load(), savedSession.refreshExpiresAt > Date() {
            session = savedSession
            currentUser = savedSession.user
        } else {
            try? self.sessionStore.clear()
        }
        observeFCMTokenChanges()
    }

    var isAuthenticated: Bool { currentUser != nil && session != nil }
    var currentRole: HEROSUserRole { currentUser?.role ?? .trustedContact }
    var verificationEmail: String { pendingEmail ?? "email của bạn" }
    var verificationPurpose: EmailOTPPurpose { pendingPurpose ?? .login }
    var activeAccessToken: String? { session?.accessToken }

    func requestLoginOTP(email: String) {
        let normalizedEmail = normalizeEmail(email)
        guard isValidEmail(normalizedEmail) else {
            errorMessage = AuthValidationError.invalidEmail.localizedDescription
            return
        }

        perform {
            let challenge = try await self.authService.requestEmailOTP(email: normalizedEmail, purpose: .login)
            self.pendingEmail = normalizedEmail
            self.pendingPurpose = .login
            self.otpChallenge = challenge
            self.authStep = .verifyOTP
        }
    }

    func beginRegistration(
        fullName: String,
        email: String,
        phone: String,
        dateOfBirth: Date,
        role: HEROSUserRole,
        password: String
    ) {
        let normalizedEmail = normalizeEmail(email)
        let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedName.isEmpty, !normalizedPhone.isEmpty else {
            errorMessage = AuthValidationError.missingInformation.localizedDescription
            return
        }
        guard isValidEmail(normalizedEmail) else {
            errorMessage = AuthValidationError.invalidEmail.localizedDescription
            return
        }
        guard (8...128).contains(password.count) else {
            errorMessage = AuthValidationError.invalidPassword.localizedDescription
            return
        }

        let registration = PendingRegistration(
            fullName: normalizedName,
            email: normalizedEmail,
            phone: normalizedPhone,
            dateOfBirth: dateOfBirth,
            role: role,
            password: password
        )

        perform {
            let challenge = try await self.authService.requestEmailOTP(email: normalizedEmail, purpose: .register)
            self.pendingRegistration = registration
            self.pendingEmail = normalizedEmail
            self.pendingPurpose = .register
            self.otpChallenge = challenge
            self.authStep = .verifyOTP
        }
    }

    func verifyOTP(_ code: String) {
        let otp = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard otp.count == 6, otp.allSatisfy(\.isNumber) else {
            errorMessage = AuthValidationError.invalidOTP.localizedDescription
            return
        }
        guard let email = pendingEmail, let purpose = pendingPurpose else {
            errorMessage = AuthValidationError.noPendingAuthentication.localizedDescription
            return
        }

        perform {
            let authenticatedSession: AuthSession
            switch purpose {
            case .login:
                authenticatedSession = try await self.authService.loginWithEmailOTP(
                    email: email,
                    otp: otp,
                    deviceId: self.installationIDProvider.deviceId
                )
            case .register:
                guard let registration = self.pendingRegistration else {
                    throw AuthValidationError.noPendingAuthentication
                }
                authenticatedSession = try await self.authService.register(
                    registration,
                    otp: otp,
                    deviceId: self.installationIDProvider.deviceId
                )
            }
            try self.sessionStore.save(authenticatedSession)
            self.completeAuthentication(authenticatedSession)
        }
    }

    func resendOTP() {
        guard let email = pendingEmail, let purpose = pendingPurpose else {
            errorMessage = AuthValidationError.noPendingAuthentication.localizedDescription
            return
        }
        perform {
            self.otpChallenge = try await self.authService.requestEmailOTP(email: email, purpose: purpose)
        }
    }

    func requestAccountDeletionOTP() {
        guard session != nil else {
            errorMessage = AuthValidationError.noActiveSession.localizedDescription
            return
        }

        perform {
            self.accountDeletionChallenge = try await self.performAuthenticatedRequest { accessToken in
                try await self.authService.requestAccountDeletionOTP(accessToken: accessToken)
            }
        }
    }

    func deleteAccount(otp code: String) {
        let otp = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard otp.count == 6, otp.allSatisfy(\.isNumber) else {
            errorMessage = AuthValidationError.invalidOTP.localizedDescription
            return
        }
        guard session != nil else {
            errorMessage = AuthValidationError.noActiveSession.localizedDescription
            return
        }
        guard let challengeId = accountDeletionChallenge?.challengeId else {
            errorMessage = AuthValidationError.noPendingAuthentication.localizedDescription
            return
        }

        perform {
            _ = try await self.performAuthenticatedRequest { accessToken in
                try await self.authService.deleteAccount(
                    challengeId: challengeId,
                    otp: otp,
                    accessToken: accessToken
                )
            }
            try self.sessionStore.clear()
            self.clearSensitiveLocalData()
            self.session = nil
            self.currentUser = nil
            self.accountDeletionChallenge = nil
            self.clearPendingAuthentication()
            self.authStep = .signIn
        }
    }

    func cancelAccountDeletion() {
        guard !isLoading else { return }
        accountDeletionChallenge = nil
        errorMessage = nil
    }

    func updateAvatar(imageData: Data) {
        guard !isUpdatingAvatar else { return }
        guard session != nil else {
            errorMessage = AuthValidationError.noActiveSession.localizedDescription
            return
        }

        isUpdatingAvatar = true
        errorMessage = nil
        Task {
            defer { isUpdatingAvatar = false }
            do {
                let uploadData = try await Task.detached(priority: .userInitiated) {
                    try AvatarImageProcessor.makeUploadJPEG(from: imageData)
                }.value
                let result = try await performAuthenticatedRequest { accessToken in
                    try await self.authService.uploadAvatar(data: uploadData, accessToken: accessToken)
                }
                guard var activeSession = session, var user = currentUser else {
                    throw AuthValidationError.noActiveSession
                }
                user.avatarURL = result.avatarUrl
                activeSession = AuthSession(
                    accessToken: activeSession.accessToken,
                    refreshToken: activeSession.refreshToken,
                    refreshExpiresAt: activeSession.refreshExpiresAt,
                    user: user
                )
                try sessionStore.save(activeSession)
                session = activeSession
                currentUser = user
            } catch {
                errorMessage = userFacingMessage(for: error)
            }
        }
    }

    func handleInvitationURL(_ url: URL) {
        guard let code = ContactInviteURLParser.code(from: url) else { return }
        setPendingInviteCode(code)
    }

    func setPendingInviteCode(_ value: String) {
        guard let code = ContactInviteURLParser.normalize(value) else {
            inviteResultMessage = "Mã lời mời phải gồm 32 ký tự hexadecimal."
            return
        }
        do {
            try pendingInviteStore.save(code)
            pendingInviteCode = code
            inviteResultMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    func dismissPendingInvite() {
        pendingInviteCode = nil
        try? pendingInviteStore.clear()
    }

    func acceptPendingInvite() {
        guard !isAcceptingInvite, let code = pendingInviteCode else { return }
        guard isAuthenticated else {
            inviteResultMessage = "Vui lòng đăng nhập tài khoản người thân để xác nhận lời mời."
            return
        }

        isAcceptingInvite = true
        inviteResultMessage = nil
        Task {
            defer { isAcceptingInvite = false }
            do {
                try await performAuthenticatedRequest { accessToken in
                    try await self.emergencyContactsRepository.acceptInviteCode(code, accessToken: accessToken)
                }
                dismissPendingInvite()
                inviteResultMessage = "Đã kết nối với người thân."
                NotificationCenter.default.post(name: .emergencyRelationshipsDidChange, object: nil)
            } catch {
                inviteResultMessage = userFacingMessage(for: error)
            }
        }
    }

    func signOut() {
        if let activeSession = session {
            let deviceId = installationIDProvider.deviceId
            Task {
                try? await pushDeviceRepository.unregister(
                    deviceId: deviceId,
                    accessToken: activeSession.accessToken
                )
            }
        }
        try? sessionStore.clear()
        try? pendingInviteStore.clear()
        session = nil
        currentUser = nil
        pendingInviteCode = nil
        clearPendingAuthentication()
        authStep = .signIn
        errorMessage = nil
        SecureAudioCache.clear()
        NotificationCenter.default.post(name: .appSessionDidInvalidate, object: nil)
    }

    func activatePushNotifications() {
        Task {
            await PushNotificationCoordinator.requestAuthorization()
            guard FirebaseApp.app() != nil else { return }
            guard let token = try? await Messaging.messaging().token() else { return }
            registerPushToken(token)
        }
    }

    func resetToSignIn() {
        clearPendingAuthentication()
        authStep = .signIn
        errorMessage = nil
    }

    func resetToSignUp() {
        clearPendingAuthentication()
        authStep = .signUp
        errorMessage = nil
    }

    private func perform(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await operation()
            } catch {
                errorMessage = userFacingMessage(for: error)
            }
        }
    }

    private func completeAuthentication(_ authenticatedSession: AuthSession) {
        session = authenticatedSession
        currentUser = authenticatedSession.user
        clearPendingAuthentication()
        authStep = .signIn
        NotificationCenter.default.post(name: .authenticationTokenDidChange, object: nil)
        activatePushNotifications()
    }

    private func clearPendingAuthentication() {
        pendingRegistration = nil
        pendingEmail = nil
        pendingPurpose = nil
        otpChallenge = nil
    }

    private func clearSensitiveLocalData() {
        URLCache.shared.removeAllCachedResponses()
        try? pendingInviteStore.clear()
        pendingInviteCode = nil
        SecureAudioCache.clear()
        NotificationCenter.default.post(name: .appSessionDidInvalidate, object: nil)

        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
              let cachedItems = try? FileManager.default.contentsOfDirectory(
                at: cachesURL,
                includingPropertiesForKeys: nil
              ) else { return }

        cachedItems.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    func performAuthenticatedRequest<T>(
        _ request: @escaping (String) async throws -> T
    ) async throws -> T {
        guard let activeSession = session else {
            throw AuthValidationError.noActiveSession
        }

        do {
            return try await request(activeSession.accessToken)
        } catch let error as APIError where error.statusCode == 401 {
            let tokens: AuthTokenSet
            do {
                tokens = try await authService.refreshSession(
                    refreshToken: activeSession.refreshToken,
                    deviceId: installationIDProvider.deviceId
                )
            } catch {
                invalidateExpiredSession()
                throw AuthValidationError.noActiveSession
            }

            let refreshedSession = AuthSession(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                refreshExpiresAt: tokens.refreshExpiresAt,
                user: activeSession.user
            )
            try sessionStore.save(refreshedSession)
            session = refreshedSession
            NotificationCenter.default.post(name: .authenticationTokenDidChange, object: nil)
            if let pushToken { registerPushToken(pushToken) }
            return try await request(refreshedSession.accessToken)
        }
    }

    private func invalidateExpiredSession() {
        try? sessionStore.clear()
        session = nil
        currentUser = nil
        accountDeletionChallenge = nil
        clearPendingAuthentication()
        authStep = .signIn
        SecureAudioCache.clear()
        NotificationCenter.default.post(name: .appSessionDidInvalidate, object: nil)
    }

    private func observeFCMTokenChanges() {
        NotificationCenter.default.publisher(for: .fcmTokenDidRefresh)
            .compactMap { $0.userInfo?["token"] as? String }
            .receive(on: RunLoop.main)
            .sink { [weak self] token in self?.registerPushToken(token) }
            .store(in: &cancellables)
    }

    private func registerPushToken(_ token: String) {
        pushToken = token
        guard session != nil else { return }
        Task {
            try? await performAuthenticatedRequest { accessToken in
                try await self.pushDeviceRepository.register(
                    deviceId: self.installationIDProvider.deviceId,
                    pushToken: token,
                    accessToken: accessToken
                )
            }
        }
    }

    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    private func userFacingMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.serverMessage ?? apiError.localizedDescription
        }
        return error.localizedDescription
    }
}
