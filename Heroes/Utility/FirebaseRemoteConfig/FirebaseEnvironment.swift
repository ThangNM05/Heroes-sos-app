//
//  FirebaseEnvironment.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

class FirebaseEnvironment: AbstractEnvironment {
    static let shared = FirebaseEnvironment()

    private var remoteConfig: RemoteConfig?

    private init() {}

    func setupFirebase() {
        print("🔥 [FirebaseEnvironment] Setting up Firebase...")
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        FirebaseConfiguration.shared.setLoggerLevel(.error)

        remoteConfig = RemoteConfig.remoteConfig()
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig?.configSettings = settings
        #endif
    }

    func fetchConfig(completion: (() -> Void)? = nil) {
        if remoteConfig == nil {
            setupFirebase()
        }

        print("🔥 [FirebaseEnvironment] Fetching RemoteConfig parameters...")
        remoteConfig?.fetch { [weak self] status, error in
            if status == .success {
                print("FirebaseEnvironment: Config fetched!")
                self?.remoteConfig?.activate(completion: nil)
            } else {
                print("FirebaseEnvironment: Config not fetched - Error: \(error?.localizedDescription ?? "Unknown")")
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    func getStringValue(fromKey key: RemoteConfigKey) -> String {
        return remoteConfig?.configValue(forKey: key.rawValue).stringValue ?? ""
    }

    func getBooleanValue(fromKey key: RemoteConfigKey) -> Bool {
        return remoteConfig?.configValue(forKey: key.rawValue).boolValue ?? false
    }

    func getNumberValue(fromKey key: RemoteConfigKey) -> NSNumber {
        return remoteConfig?.configValue(forKey: key.rawValue).numberValue ?? 0
    }
}
