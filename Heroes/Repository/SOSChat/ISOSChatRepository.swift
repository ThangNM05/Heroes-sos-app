//
//  ISOSChatRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ISOSChatRepository {
    func list(status: SOSChatStatus, before: String?, accessToken: String) async throws -> SOSChatListPage
    func detail(id: String, accessToken: String) async throws -> SOSChatDetail
    func messages(id: String, before: Int?, after: Int?, accessToken: String) async throws -> SOSChatMessagePage
    func send(id: String, request: SOSChatMessageRequest, accessToken: String) async throws -> SOSChatMessage
}

