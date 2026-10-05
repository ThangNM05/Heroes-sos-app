//
//  ISOSChatService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ISOSChatService {
    func list(status: SOSChatStatus, before: String?, session: AppSessionStore) async throws -> SOSChatListPage
    func detail(id: String, session: AppSessionStore) async throws -> SOSChatDetail
    func messages(id: String, before: Int?, after: Int?, session: AppSessionStore) async throws -> SOSChatMessagePage
    func send(id: String, request: SOSChatMessageRequest, session: AppSessionStore) async throws -> SOSChatMessage
    func acknowledge(id: String, mode: SOSSupportMode, session: AppSessionStore) async throws
}

