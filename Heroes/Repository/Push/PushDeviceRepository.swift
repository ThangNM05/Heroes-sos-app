import Foundation
import Moya
import Alamofire

protocol IPushDeviceRepository: AnyObject {
    func register(deviceId: String, pushToken: String, accessToken: String) async throws
    func unregister(deviceId: String, accessToken: String) async throws
}

final class PushDeviceRepository: IPushDeviceRepository {
    private let networkClient: INetworkClient

    init(networkClient: INetworkClient) {
        self.networkClient = networkClient
    }

    func register(deviceId: String, pushToken: String, accessToken: String) async throws {
        let _: IgnoredPushResponse = try await networkClient.requestEnvelope(
            path: "/me/devices",
            method: .post,
            headers: APIHeaders.json(accessToken: accessToken),
            jsonBody: RegisterPushDeviceBody(deviceId: deviceId, platform: "ios", pushToken: pushToken)
        )
    }

    func unregister(deviceId: String, accessToken: String) async throws {
        let safeID = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? deviceId
        let _: IgnoredPushResponse = try await networkClient.requestEnvelope(
            path: "/me/devices/\(safeID)",
            method: .delete,
            headers: APIHeaders.json(accessToken: accessToken)
        )
    }
}

private struct RegisterPushDeviceBody: Encodable {
    let deviceId: String
    let platform: String
    let pushToken: String
}

private struct IgnoredPushResponse: Decodable {
    init(from decoder: Decoder) throws {}
}
