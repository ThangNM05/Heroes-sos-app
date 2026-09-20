//
//  FirebaseHelper.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

final class FirebaseHelper {
    static let shared = FirebaseHelper()

    private(set) var isConfigured: Bool = false

    private init() {}

    /// Initialize Firebase services (Core, RemoteConfig, Analytics, Crashlytics)
    func configure() {
        guard !isConfigured else { return }
        print("🔥 [FirebaseHelper] Configuring real Firebase services...")
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        FirebaseEnvironment.shared.setupFirebase()
        isConfigured = true
        print("✅ [FirebaseHelper] Real Firebase configured successfully.")
    }

    /// Fetch Firebase Remote Config parameters
    func fetchRemoteConfig() async -> Bool {
        return await withCheckedContinuation { continuation in
            FirebaseEnvironment.shared.fetchConfig {
                continuation.resume(returning: true)
            }
        }
    }

    /// Log custom Analytics event
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    /// Record non-fatal error to Crashlytics
    func recordError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
