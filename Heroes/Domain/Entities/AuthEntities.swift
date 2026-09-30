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

enum MockAuthStep: Equatable {
    case signIn
    case signUp
    case verifyOTP
    case bindDevice
}

enum MockAuthError: LocalizedError {
    case invalidCredentials
    case duplicateEmail
    case invalidOTP
    case deviceAlreadyBound
    case missingInformation

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email hoặc mật khẩu không đúng."
        case .duplicateEmail:
            return "Email này đã được đăng ký."
        case .invalidOTP:
            return "Mã OTP không đúng. Mã demo là 123456."
        case .deviceAlreadyBound:
            return "Thiết bị đã được liên kết với tài khoản khác."
        case .missingInformation:
            return "Vui lòng nhập đầy đủ thông tin bắt buộc."
        }
    }
}
