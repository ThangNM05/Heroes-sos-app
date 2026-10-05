import Foundation
import Moya
import Alamofire

final class SOSAPIRepository: ISOSAPIRepository {
    private let networkClient: INetworkClient

    init(networkClient: INetworkClient) {
        self.networkClient = networkClient
    }

    func createSOS(
        location: SOSLocationUpdate,
        message: String?,
        clientRequestId: String,
        accessToken: String
    ) async throws -> SOSAlert {
        let response: SOSDTO = try await networkClient.requestEnvelope(
            path: "/sos",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: CreateSOSBody(
                clientRequestId: clientRequestId,
                message: message,
                location: LocationBody(location)
            )
        )
        return response.domain
    }

    func fetchOwnerActiveSOS(accessToken: String) async throws -> SOSAlert? {
        let response: SOSDTO? = try await networkClient.requestEnvelope(
            path: "/sos/active",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return response?.domain
    }

    func fetchIncomingSOS(accessToken: String) async throws -> [SOSAlert] {
        let response: SOSListPayload = try await networkClient.requestEnvelope(
            path: "/sos/incoming/active",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return response.items.map(\.domain)
    }

    func fetchSOS(id: String, accessToken: String) async throws -> SOSAlert {
        let response: SOSDTO = try await networkClient.requestEnvelope(
            path: "/sos/\(id.apiPathComponent)",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return response.domain
    }

    func updateLocation(sosId: String, location: SOSLocationUpdate, accessToken: String) async throws -> SOSAlert {
        let response: SOSDTO = try await networkClient.requestEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/location",
            method: .put,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: LocationBody(location)
        )
        return response.domain
    }

    func acknowledge(sosId: String, mode: SOSSupportMode, accessToken: String) async throws -> SOSAcknowledgement {
        let response: SOSAcknowledgementDTO = try await networkClient.requestEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/acknowledge",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: AcknowledgeBody(supportMode: mode.rawValue)
        )
        return response.domain
    }

    func resolve(sosId: String, accessToken: String) async throws {
        let _: IgnoredSOSResponse = try await networkClient.requestEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/resolve",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }

    func cancel(sosId: String, reason: String?, accessToken: String) async throws {
        let _: IgnoredSOSResponse = try await networkClient.requestEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/cancel",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: CancelBody(reason: reason)
        )
    }

    func fetchOwnerRecordings(accessToken: String) async throws -> [AudioRecord] {
        let response: RecordingListPayload = try await networkClient.requestEnvelope(
            path: "/sos/recordings",
            headers: APIHeaders.json(accessToken: accessToken)
        )
        return response.items.map { $0.domain(defaultSOSId: $0.sosId) }
    }

    func uploadRecording(
        sosId: String,
        data: Data,
        durationSeconds: Int,
        fileName: String,
        mimeType: String,
        accessToken: String
    ) async throws -> AudioRecord {
        let parts = [
            Moya.MultipartFormData(provider: .data(data), name: "audio", fileName: fileName, mimeType: mimeType),
            Moya.MultipartFormData(provider: .data(Data(String(durationSeconds).utf8)), name: "durationSeconds")
        ]
        let response: RecordingDTO = try await networkClient.uploadMultipartEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/recordings",
            parts: parts,
            headers: APIHeaders.multipart(accessToken: accessToken)
        )
        return response.domain(defaultSOSId: sosId)
    }

    func downloadRecording(sosId: String, recordingId: String, accessToken: String) async throws -> ProtectedAudioDownload {
        let target = APIEndpoint(
            path: "/sos/\(sosId.apiPathComponent)/recordings/\(recordingId.apiPathComponent)",
            headers: APIHeaders.binary(accessToken: accessToken)
        )
        let response = try await networkClient.response(target)
        return ProtectedAudioDownload(
            data: response.data,
            mimeType: response.response?.value(forHTTPHeaderField: "Content-Type")
        )
    }

    func deleteRecording(sosId: String, recordingId: String, accessToken: String) async throws {
        let _: IgnoredSOSResponse = try await networkClient.requestEnvelope(
            path: "/sos/\(sosId.apiPathComponent)/recordings/\(recordingId.apiPathComponent)",
            method: .delete,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }
}

private struct CreateSOSBody: Encodable {
    let clientRequestId: String
    let message: String?
    let location: LocationBody
}

private struct LocationBody: Encodable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let recordedAt: Date
    let address: String?

    init(_ value: SOSLocationUpdate) {
        latitude = value.latitude
        longitude = value.longitude
        accuracy = value.accuracy
        recordedAt = value.recordedAt
        address = value.address
    }
}

private struct AcknowledgeBody: Encodable { let supportMode: String }
private struct CancelBody: Encodable { let reason: String? }

private struct SOSListPayload: Decodable {
    let items: [SOSDTO]
    private enum CodingKeys: String, CodingKey { case items, alerts, sos }

    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode([SOSDTO].self) {
            items = value
            return
        }
        if let single = try? decoder.singleValueContainer().decode(SOSDTO.self) {
            items = [single]
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([SOSDTO].self, forKey: .items)
            ?? container.decodeIfPresent([SOSDTO].self, forKey: .alerts)
            ?? container.decodeIfPresent([SOSDTO].self, forKey: .sos)
            ?? []
    }
}

private struct RecordingListPayload: Decodable {
    let items: [RecordingDTO]
    private enum CodingKeys: String, CodingKey { case items, recordings }

    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode([RecordingDTO].self) {
            items = value
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([RecordingDTO].self, forKey: .items)
            ?? container.decodeIfPresent([RecordingDTO].self, forKey: .recordings)
            ?? []
    }
}

private struct SOSDTO: Decodable {
    let id: String
    let ownerId: String?
    let ownerName: String?
    let ownerPhone: String?
    let ownerAvatarUrl: String?
    let message: String?
    let status: String?
    let startedAt: Date?
    let currentLocation: LocationDTO?
    let responderCount: Int?
    let viewerAcknowledged: Bool?
    let viewerSupportMode: String?
    let recordings: [RecordingDTO]?
    let chatId: String?
    let chatPath: String?

    private struct Owner: Decodable {
        let id: String?
        let fullName: String?
        let phone: String?
        let avatarUrl: String?
        private enum CodingKeys: String, CodingKey { case id, mongoID = "_id", fullName, phone, avatarUrl }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(String.self, forKey: .id) ?? c.decodeIfPresent(String.self, forKey: .mongoID)
            fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
            phone = try c.decodeIfPresent(String.self, forKey: .phone)
            avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, mongoID = "_id", owner, ownerId, ownerName, ownerPhone, ownerAvatarUrl
        case message, status, startedAt, createdAt, currentLocation, location
        case responderCount, respondersCount, viewerAcknowledged, viewerSupportMode, supportMode, recordings
        case chatId, chatPath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? c.decode(String.self, forKey: .mongoID)
        let owner = try c.decodeIfPresent(Owner.self, forKey: .owner)
            ?? c.decodeIfPresent(Owner.self, forKey: .ownerId)
        ownerId = owner?.id ?? (try? c.decode(String.self, forKey: .ownerId))
        ownerName = try c.decodeIfPresent(String.self, forKey: .ownerName) ?? owner?.fullName
        ownerPhone = try c.decodeIfPresent(String.self, forKey: .ownerPhone) ?? owner?.phone
        ownerAvatarUrl = try c.decodeIfPresent(String.self, forKey: .ownerAvatarUrl) ?? owner?.avatarUrl
        message = try c.decodeIfPresent(String.self, forKey: .message)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt) ?? c.decodeIfPresent(Date.self, forKey: .createdAt)
        currentLocation = try c.decodeIfPresent(LocationDTO.self, forKey: .currentLocation)
            ?? c.decodeIfPresent(LocationDTO.self, forKey: .location)
        responderCount = try c.decodeIfPresent(Int.self, forKey: .responderCount)
            ?? c.decodeIfPresent(Int.self, forKey: .respondersCount)
        viewerAcknowledged = try c.decodeIfPresent(Bool.self, forKey: .viewerAcknowledged)
        viewerSupportMode = try c.decodeIfPresent(String.self, forKey: .viewerSupportMode)
            ?? c.decodeIfPresent(String.self, forKey: .supportMode)
        recordings = try c.decodeIfPresent([RecordingDTO].self, forKey: .recordings)
        chatId = try c.decodeIfPresent(String.self, forKey: .chatId)
        chatPath = try c.decodeIfPresent(String.self, forKey: .chatPath)
    }

    var domain: SOSAlert {
        let location = currentLocation ?? LocationDTO.empty
        let mappedStatus: SOSAlert.SOSStatus
        switch status?.lowercased() {
        case "resolved": mappedStatus = .resolved
        case "cancelled", "canceled": mappedStatus = .cancelled
        case "acknowledged", "responding": mappedStatus = .responding
        default: mappedStatus = .active
        }
        return SOSAlert(
            id: id,
            senderId: ownerId ?? "",
            senderName: ownerName ?? "Người dùng HEROS",
            senderPhone: ownerPhone ?? "",
            senderAvatarURL: ownerAvatarUrl,
            latitude: location.latitude,
            longitude: location.longitude,
            addressName: location.address ?? String(format: "%.6f, %.6f", location.latitude, location.longitude),
            createdAt: startedAt ?? Date(),
            status: mappedStatus,
            recipientMode: .trustedContactsOnly,
            audioRecords: (recordings ?? []).map { $0.domain(defaultSOSId: id) },
            isHardwareTriggered: false,
            respondersCount: responderCount ?? 0,
            message: message,
            viewerAcknowledged: viewerAcknowledged ?? false,
            viewerSupportMode: viewerSupportMode.flatMap(SOSSupportMode.init(rawValue:)),
            chatId: chatId,
            chatPath: chatPath
        )
    }
}

private struct LocationDTO: Decodable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let recordedAt: Date?
    let address: String?

    static let empty = LocationDTO(latitude: 0, longitude: 0, accuracy: nil, recordedAt: nil, address: nil)

    private enum CodingKeys: String, CodingKey { case latitude, longitude, coordinates, accuracy, recordedAt, address }

    init(latitude: Double, longitude: Double, accuracy: Double?, recordedAt: Date?, address: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.recordedAt = recordedAt
        self.address = address
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let coordinates = try c.decodeIfPresent([Double].self, forKey: .coordinates)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude) ?? coordinates?.first ?? 0
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude) ?? coordinates?.dropFirst().first ?? 0
        accuracy = try c.decodeIfPresent(Double.self, forKey: .accuracy)
        recordedAt = try c.decodeIfPresent(Date.self, forKey: .recordedAt)
        address = try c.decodeIfPresent(String.self, forKey: .address)
    }
}

private struct RecordingDTO: Decodable {
    let id: String
    let sosId: String?
    let durationSeconds: Int?
    let recordedAt: Date?
    let createdAt: Date?
    let expiresAt: Date?
    let mimeType: String?
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case id, mongoID = "_id", sosId, durationSeconds, recordedAt, createdAt, expiresAt, mimeType, contentType, title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? c.decode(String.self, forKey: .mongoID)
        sosId = try c.decodeIfPresent(String.self, forKey: .sosId)
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds)
        recordedAt = try c.decodeIfPresent(Date.self, forKey: .recordedAt)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        mimeType = try c.decodeIfPresent(String.self, forKey: .mimeType) ?? c.decodeIfPresent(String.self, forKey: .contentType)
        title = try c.decodeIfPresent(String.self, forKey: .title)
    }

    func domain(defaultSOSId: String?) -> AudioRecord {
        AudioRecord(
            id: id,
            title: title ?? "Bản ghi SOS",
            durationSeconds: durationSeconds ?? 0,
            recordedAt: recordedAt ?? createdAt ?? Date(),
            fileURL: "/sos/\(defaultSOSId ?? sosId ?? "")/recordings/\(id)",
            isEvidence: true,
            expiresAt: expiresAt,
            isOwnerOnly: false,
            sosId: sosId ?? defaultSOSId,
            mimeType: mimeType
        )
    }
}

private struct SOSAcknowledgementDTO: Decodable {
    let viewerAcknowledged: Bool?
    let responderCount: Int?
    let supportMode: String?

    var domain: SOSAcknowledgement {
        SOSAcknowledgement(
            viewerAcknowledged: viewerAcknowledged ?? true,
            responderCount: responderCount ?? 0,
            supportMode: supportMode.flatMap(SOSSupportMode.init(rawValue:))
        )
    }
}

private struct IgnoredSOSResponse: Decodable {
    init(from decoder: Decoder) throws {}
}

private extension String {
    var apiPathComponent: String { addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self }
}
