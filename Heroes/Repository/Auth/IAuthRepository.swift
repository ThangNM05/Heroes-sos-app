import Foundation

protocol IAuthRepository: AnyObject {
    func requestEmailOTP(email: String, purpose: EmailOTPPurpose) async throws -> EmailOTPChallenge
    func loginWithEmailOTP(email: String, otp: String, deviceId: String) async throws -> AuthSession
    func register(_ registration: PendingRegistration, otp: String, deviceId: String) async throws -> AuthSession
    func refreshSession(refreshToken: String, deviceId: String) async throws -> AuthTokenSet
    func uploadAvatar(data: Data, accessToken: String) async throws -> AvatarUploadResult
    func requestAccountDeletionOTP(accessToken: String) async throws -> AccountDeletionChallenge
    func deleteAccount(challengeId: String, otp: String, accessToken: String) async throws -> AccountDeletionReceipt
}
