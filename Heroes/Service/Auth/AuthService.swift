import Foundation

final class AuthService: IAuthService {
    private let repository: IAuthRepository

    init(repository: IAuthRepository) {
        self.repository = repository
    }

    func requestEmailOTP(email: String, purpose: EmailOTPPurpose) async throws -> EmailOTPChallenge {
        try await repository.requestEmailOTP(email: email, purpose: purpose)
    }

    func loginWithEmailOTP(email: String, otp: String, deviceId: String) async throws -> AuthSession {
        try await repository.loginWithEmailOTP(email: email, otp: otp, deviceId: deviceId)
    }

    func register(_ registration: PendingRegistration, otp: String, deviceId: String) async throws -> AuthSession {
        try await repository.register(registration, otp: otp, deviceId: deviceId)
    }

    func refreshSession(refreshToken: String, deviceId: String) async throws -> AuthTokenSet {
        try await repository.refreshSession(refreshToken: refreshToken, deviceId: deviceId)
    }

    func uploadAvatar(data: Data, accessToken: String) async throws -> AvatarUploadResult {
        try await repository.uploadAvatar(data: data, accessToken: accessToken)
    }

    func requestAccountDeletionOTP(accessToken: String) async throws -> AccountDeletionChallenge {
        try await repository.requestAccountDeletionOTP(accessToken: accessToken)
    }

    func deleteAccount(
        challengeId: String,
        otp: String,
        accessToken: String
    ) async throws -> AccountDeletionReceipt {
        try await repository.deleteAccount(
            challengeId: challengeId,
            otp: otp,
            accessToken: accessToken
        )
    }
}
