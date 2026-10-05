import Foundation

struct SOSAcknowledgement: Equatable {
    let viewerAcknowledged: Bool
    let responderCount: Int
    let supportMode: SOSSupportMode?
}

struct ProtectedAudioDownload {
    let data: Data
    let mimeType: String?
}

protocol ISOSAPIRepository: AnyObject {
    func createSOS(location: SOSLocationUpdate, message: String?, clientRequestId: String, accessToken: String) async throws -> SOSAlert
    func fetchOwnerActiveSOS(accessToken: String) async throws -> SOSAlert?
    func fetchIncomingSOS(accessToken: String) async throws -> [SOSAlert]
    func fetchSOS(id: String, accessToken: String) async throws -> SOSAlert
    func updateLocation(sosId: String, location: SOSLocationUpdate, accessToken: String) async throws -> SOSAlert
    func acknowledge(sosId: String, mode: SOSSupportMode, accessToken: String) async throws -> SOSAcknowledgement
    func resolve(sosId: String, accessToken: String) async throws
    func cancel(sosId: String, reason: String?, accessToken: String) async throws
    func fetchOwnerRecordings(accessToken: String) async throws -> [AudioRecord]
    func uploadRecording(sosId: String, data: Data, durationSeconds: Int, fileName: String, mimeType: String, accessToken: String) async throws -> AudioRecord
    func downloadRecording(sosId: String, recordingId: String, accessToken: String) async throws -> ProtectedAudioDownload
    func deleteRecording(sosId: String, recordingId: String, accessToken: String) async throws
}
