import Foundation

protocol InstallationIDProviding: AnyObject {
    var deviceId: String { get }
}

final class InstallationIDProvider: InstallationIDProviding {
    private let defaults: UserDefaults
    private let key = "vn.nextteam.heros.installation-id"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var deviceId: String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let value = UUID().uuidString.lowercased()
        defaults.set(value, forKey: key)
        return value
    }
}
