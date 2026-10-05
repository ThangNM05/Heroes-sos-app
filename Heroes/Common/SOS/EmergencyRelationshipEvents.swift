import Foundation

extension Notification.Name {
    static let emergencyRelationshipsDidChange = Notification.Name("EmergencyRelationshipsDidChange")
    static let appSessionDidInvalidate = Notification.Name("AppSessionDidInvalidate")
    static let authenticationTokenDidChange = Notification.Name("AuthenticationTokenDidChange")
    static let sosPushReceived = Notification.Name("SOSPushReceived")
    static let fcmTokenDidRefresh = Notification.Name("FCMTokenDidRefresh")
}

enum SecureAudioCache {
    private static var directory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("HEROS-Audio", isDirectory: true)
    }

    static func cachedURL(recordingId: String, mimeType: String?) -> URL? {
        let url = fileURL(recordingId: recordingId, mimeType: mimeType)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func store(_ data: Data, recordingId: String, mimeType: String?) throws -> URL {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        let url = fileURL(recordingId: recordingId, mimeType: mimeType)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
        return url
    }

    static func clear() {
        URLCache.shared.removeAllCachedResponses()
        try? FileManager.default.removeItem(at: directory)
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let audioDirectory = caches.appendingPathComponent("HEROS/Audio", isDirectory: true)
        try? FileManager.default.removeItem(at: audioDirectory)
    }

    private static func fileURL(recordingId: String, mimeType: String?) -> URL {
        let safeID = recordingId.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
        let ext: String
        switch mimeType?.lowercased() {
        case let value? where value.contains("mpeg"): ext = "mp3"
        case let value? where value.contains("wav"): ext = "wav"
        case let value? where value.contains("ogg"): ext = "ogg"
        case let value? where value.contains("aac"): ext = "aac"
        default: ext = "m4a"
        }
        return directory.appendingPathComponent(safeID).appendingPathExtension(ext)
    }
}
