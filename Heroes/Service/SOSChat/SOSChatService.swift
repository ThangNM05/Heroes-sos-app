//
//  SOSChatService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation


final class SOSChatService: ISOSChatService {
    private let repository: ISOSChatRepository
    private let sosRepository: ISOSAPIRepository
    init(repository: ISOSChatRepository, sosRepository: ISOSAPIRepository) {
        self.repository = repository
        self.sosRepository = sosRepository
    }

    func acknowledge(id: String, mode: SOSSupportMode, session: AppSessionStore) async throws {
        _ = try await session.performAuthenticatedRequest {
            try await self.sosRepository.acknowledge(sosId: id, mode: mode, accessToken: $0)
        }
    }

    func list(status: SOSChatStatus, before: String?, session: AppSessionStore) async throws -> SOSChatListPage {
        try await session.performAuthenticatedRequest {
            try await self.repository.list(status: status, before: before, accessToken: $0)
        }
    }
    func detail(id: String, session: AppSessionStore) async throws -> SOSChatDetail {
        try await session.performAuthenticatedRequest { try await self.repository.detail(id: id, accessToken: $0) }
    }
    func messages(id: String, before: Int?, after: Int?, session: AppSessionStore) async throws -> SOSChatMessagePage {
        try await session.performAuthenticatedRequest {
            try await self.repository.messages(id: id, before: before, after: after, accessToken: $0)
        }
    }
    func send(id: String, request: SOSChatMessageRequest, session: AppSessionStore) async throws -> SOSChatMessage {
        try await session.performAuthenticatedRequest {
            try await self.repository.send(id: id, request: request, accessToken: $0)
        }
    }
}
