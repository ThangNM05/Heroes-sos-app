//
//  SOSChatPushRouter.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

/// Retains notification taps received before the SwiftUI hierarchy is ready.
@MainActor
final class SOSChatPushRouter: ObservableObject {
    static let shared = SOSChatPushRouter()
    @Published var pendingChatId: String?
    private init() {}
}

