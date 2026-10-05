import Foundation
import Alamofire
import Moya

final class AuthRepository: IAuthRepository {
    private let networkClient: INetworkClient

    init(networkClient: INetworkClient) {
        self.networkClient = networkClient
    }

    func requestEmailOTP(email: String, purpose: EmailOTPPurpose) async throws -> EmailOTPChallenge {
        let body = RequestEmailOTPBody(email: email, purpose: purpose.rawValue)
        return try await networkClient.requestEnvelope(
            path: "/auth/email/request-otp",
            method: .post,
            headers: APIHeaders.json(),
            jsonBody: body
        )
    }

    func loginWithEmailOTP(email: String, otp: String, deviceId: String) async throws -> AuthSession {
        let body = VerifyEmailOTPBody(
            email: email,
            purpose: EmailOTPPurpose.login.rawValue,
            otp: otp,
            deviceId: deviceId
        )
        let response: AuthSessionDTO = try await networkClient.requestEnvelope(
            path: "/auth/email/verify-otp",
            method: .post,
            headers: APIHeaders.json(),
            jsonBody: body
        )
        return try response.toDomain()
    }

    func register(_ registration: PendingRegistration, otp: String, deviceId: String) async throws -> AuthSession {
        let body = RegisterUserBody(
            email: registration.email,
            otp: otp,
            deviceId: deviceId,
            password: registration.password,
            fullName: registration.fullName,
            dateOfBirth: Self.birthDateFormatter.string(from: registration.dateOfBirth),
            phone: registration.phone,
            userType: registration.role.apiValue
        )
        let response: AuthSessionDTO = try await networkClient.requestEnvelope(
            path: "/users",
            method: .post,
            headers: APIHeaders.json(),
            jsonBody: body
        )
        return try response.toDomain()
    }

    func refreshSession(refreshToken: String, deviceId: String) async throws -> AuthTokenSet {
        let body = RefreshSessionBody(refreshToken: refreshToken, deviceId: deviceId)
        return try await networkClient.requestEnvelope(
            path: "/auth/refresh",
            method: .post,
            headers: APIHeaders.json(),
            jsonBody: body
        )
    }

    func uploadAvatar(data: Data, accessToken: String) async throws -> AvatarUploadResult {
        let avatarPart = Moya.MultipartFormData(
            provider: .data(data),
            name: "avatar",
            fileName: "avatar.jpg",
            mimeType: "image/jpeg"
        )
        return try await networkClient.uploadMultipartEnvelope(
            path: "/me/avatar",
            parts: [avatarPart],
            headers: APIHeaders.multipart(accessToken: accessToken)
        )
    }

    func requestAccountDeletionOTP(accessToken: String) async throws -> AccountDeletionChallenge {
        try await networkClient.requestEnvelope(
            path: "/me/deletion/request-otp",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }

    func deleteAccount(
        challengeId: String,
        otp: String,
        accessToken: String
    ) async throws -> AccountDeletionReceipt {
        let body = DeleteAccountBody(
            challengeId: challengeId,
            otp: otp,
            confirmation: "DELETE"
        )
        return try await networkClient.requestEnvelope(
            path: "/me",
            method: .delete,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: body
        )
    }

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct RequestEmailOTPBody: Encodable {
    let email: String
    let purpose: String
}

private struct VerifyEmailOTPBody: Encodable {
    let email: String
    let purpose: String
    let otp: String
    let deviceId: String
}

private struct RegisterUserBody: Encodable {
    let email: String
    let otp: String
    let deviceId: String
    let password: String
    let fullName: String
    let dateOfBirth: String
    let phone: String
    let userType: String
}

private struct DeleteAccountBody: Encodable {
    let challengeId: String
    let otp: String
    let confirmation: String
}

private struct RefreshSessionBody: Encodable {
    let refreshToken: String
    let deviceId: String
}

private struct AuthSessionDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let refreshExpiresAt: Date
    let user: AuthUserDTO

    func toDomain() throws -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            refreshExpiresAt: refreshExpiresAt,
            user: try user.toDomain()
        )
    }
}

private struct AuthUserDTO: Decodable {
    let id: String
    let email: String
    let fullName: String
    let phone: String
    let dateOfBirth: String
    let userType: String
    let avatarUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case email
        case fullName
        case phone
        case phoneNumber
        case dateOfBirth
        case userType
        case role
        case avatarUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .mongoID)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
            ?? container.decode(String.self, forKey: .phoneNumber)
        dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
        userType = try container.decodeIfPresent(String.self, forKey: .userType)
            ?? container.decode(String.self, forKey: .role)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    }

    func toDomain() throws -> HEROSAccount {
        guard let role = HEROSUserRole(apiValue: userType) else {
            throw AuthMappingError.unsupportedUserType(userType)
        }
        guard let birthDate = Self.parseDate(dateOfBirth) else {
            throw AuthMappingError.invalidDateOfBirth(dateOfBirth)
        }
        return HEROSAccount(
            id: id,
            fullName: fullName,
            email: email,
            phoneNumber: phone,
            dateOfBirth: birthDate,
            role: role,
            isPhoneVerified: false,
            isEmailVerified: true,
            boundDeviceSerial: nil,
            avatarURL: avatarUrl
        )
    }

    private static func parseDate(_ value: String) -> Date? {
        let birthDateFormatter = DateFormatter()
        birthDateFormatter.calendar = Calendar(identifier: .gregorian)
        birthDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        birthDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        birthDateFormatter.dateFormat = "yyyy-MM-dd"
        return birthDateFormatter.date(from: value)
            ?? fractionalISO8601.date(from: value)
            ?? standardISO8601.date(from: value)
    }

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let standardISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

private enum AuthMappingError: LocalizedError {
    case unsupportedUserType(String)
    case invalidDateOfBirth(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedUserType(let value):
            return "Loại tài khoản không được hỗ trợ: \(value)"
        case .invalidDateOfBirth:
            return "Ngày sinh trả về từ máy chủ không hợp lệ."
        }
    }
}
