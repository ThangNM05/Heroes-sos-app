//
//  SOSChatRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Alamofire

final class SOSChatRepository: ISOSChatRepository {
    private let networkClient: INetworkClient
    init(networkClient: INetworkClient) { self.networkClient = networkClient }

    func list(status: SOSChatStatus, before: String?, accessToken: String) async throws -> SOSChatListPage {
        var query = [URLQueryItem(name: "status", value: status.rawValue),
                     URLQueryItem(name: "limit", value: "20")]
        if let before { query.append(URLQueryItem(name: "before", value: before)) }
        return try await networkClient.requestEnvelope(path: "/sos-chats", queryItems: query,
                                                       headers: APIHeaders.json(accessToken: accessToken))
    }

    func detail(id: String, accessToken: String) async throws -> SOSChatDetail {
        try await networkClient.requestEnvelope(path: path(id), headers: APIHeaders.json(accessToken: accessToken))
    }

    func messages(id: String, before: Int?, after: Int?, accessToken: String) async throws -> SOSChatMessagePage {
        precondition(before == nil || after == nil, "Chat cursors are mutually exclusive")
        var query = [URLQueryItem(name: "limit", value: "100")]
        if let before { query.append(URLQueryItem(name: "beforeSequence", value: String(before))) }
        if let after { query.append(URLQueryItem(name: "afterSequence", value: String(after))) }
        return try await networkClient.requestEnvelope(path: path(id) + "/messages", queryItems: query,
                                                       headers: APIHeaders.json(accessToken: accessToken))
    }

    func send(id: String, request: SOSChatMessageRequest, accessToken: String) async throws -> SOSChatMessage {
        try await networkClient.requestEnvelope(path: path(id) + "/messages", method: .post,
                                                headers: APIHeaders.json(accessToken: accessToken), jsonBody: request)
    }

    private func path(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return "/sos-chats/" + (id.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")
    }
}
