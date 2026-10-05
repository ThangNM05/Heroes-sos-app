import Foundation

struct HEROSAccount: Identifiable, Codable, Equatable {
    let id: String
    var fullName: String
    var email: String
    var phoneNumber: String
    var dateOfBirth: Date
    var role: HEROSUserRole
    var isPhoneVerified: Bool
    var isEmailVerified: Bool
    var boundDeviceSerial: String?
    var avatarURL: String? = nil
    var gender: HEROSGender? = nil

    var initials: String {
        fullName
            .split(separator: " ")
            .suffix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

enum HEROSGender: String, Codable, CaseIterable, Identifiable {
    case female
    case male
    case other
    case undisclosed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .female: return "Nữ"
        case .male: return "Nam"
        case .other: return "Khác"
        case .undisclosed: return "Không muốn tiết lộ"
        }
    }
}

enum AuthStep: Equatable {
    case signIn
    case signUp
    case verifyOTP
}

enum EmailOTPPurpose: String, Codable {
    case login
    case register
}

struct PendingRegistration: Equatable {
    let fullName: String
    let email: String
    let phone: String
    let dateOfBirth: Date
    let role: HEROSUserRole
    let password: String
}

struct EmailOTPChallenge: Decodable, Equatable {
    let expiresAt: Date
    let purpose: EmailOTPPurpose
    let resendAfterSeconds: Int
}

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let refreshExpiresAt: Date
    let user: HEROSAccount
}

struct AuthTokenSet: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let refreshExpiresAt: Date
}

struct AvatarUploadResult: Decodable, Equatable {
    let avatarUrl: String
}

struct ProfileUpdate: Equatable {
    let fullName: String
    let dateOfBirth: Date
    let gender: HEROSGender?
}

struct PhoneOTPChallenge: Decodable, Equatable {
    let challengeId: String
    let deliveryChannel: String
    let expiresAt: Date
    let resendAfterSeconds: Int
}

struct PhoneUpdateResult: Decodable, Equatable {
    let phone: String
    let phoneOwnershipVerified: Bool
    let authorizationMethod: String
    let authorizedAt: Date
}

struct AccountDeletionChallenge: Decodable, Equatable {
    let challengeId: String
    let deliveryChannel: String?
    let expiresAt: Date?
    let resendAfterSeconds: Int?
}

struct AccountDeletionReceipt: Decodable, Equatable {
    let status: String
    let accessRevoked: Bool
}

enum AuthValidationError: LocalizedError {
    case invalidEmail
    case missingInformation
    case invalidPassword
    case invalidOTP
    case noPendingAuthentication
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Email không hợp lệ."
        case .missingInformation:
            return "Vui lòng nhập đầy đủ thông tin bắt buộc."
        case .invalidPassword:
            return "Mật khẩu phải có từ 8 đến 128 ký tự."
        case .invalidOTP:
            return "Mã OTP phải gồm đúng 6 chữ số."
        case .noPendingAuthentication:
            return "Phiên xác minh không còn hiệu lực. Vui lòng yêu cầu mã mới."
        case .noActiveSession:
            return "Phiên đăng nhập không còn hiệu lực. Vui lòng đăng nhập lại."
        }
    }
}

extension HEROSUserRole {
    var apiValue: String {
        switch self {
        case .deviceOwner: return "device_owner"
        case .trustedContact: return "emergency_contact"
        case .communityHero: return "community_responder"
        }
    }

    init?(apiValue: String) {
        switch apiValue {
        case "device_owner": self = .deviceOwner
        case "emergency_contact": self = .trustedContact
        case "community_responder": self = .communityHero
        default: return nil
        }
    }
}
