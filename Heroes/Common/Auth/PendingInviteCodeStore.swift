import Foundation
import Security

protocol PendingInviteCodeStoring: AnyObject {
    func load() throws -> String?
    func save(_ code: String) throws
    func clear() throws
}

final class KeychainPendingInviteCodeStore: PendingInviteCodeStoring {
    private let service: String
    private let account = "pending-contact-invite"

    init(service: String = Bundle.main.bundleIdentifier ?? "com.nextteam.heroes") {
        self.service = service
    }

    func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw PendingInviteKeychainError.unhandled(status)
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ code: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: Data(code.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw PendingInviteKeychainError.unhandled(updateStatus)
        }
        var insert = baseQuery
        attributes.forEach { insert[$0.key] = $0.value }
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else { throw PendingInviteKeychainError.unhandled(status) }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PendingInviteKeychainError.unhandled(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum PendingInviteKeychainError: LocalizedError {
    case unhandled(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandled(let status):
            return SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)"
        }
    }
}

enum ContactInviteURLParser {
    static func code(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let items: [URLQueryItem]
        if components.scheme?.lowercased() == "https",
           components.host?.lowercased() == "heros.nextteam.site",
           components.path == "/invite" {
            items = URLComponents(string: "?" + (components.fragment ?? ""))?.queryItems
                ?? components.queryItems
                ?? []
        } else if components.scheme?.lowercased() == "heros",
                  components.host?.lowercased() == "invite" {
            items = components.queryItems ?? []
        } else {
            return nil
        }

        guard let value = items.first(where: { $0.name.lowercased() == "code" })?.value else { return nil }
        return normalize(value)
    }

    static func normalize(_ value: String) -> String? {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.range(of: "^[A-Fa-f0-9]{32}$", options: .regularExpression) != nil else { return nil }
        return code.uppercased()
    }
}
