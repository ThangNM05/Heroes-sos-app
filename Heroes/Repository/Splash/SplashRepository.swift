//
//  SplashRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class SplashRepository: ISplashRepository {
    private let userDefaults: UserDefaults
    private let firstLaunchKey = "base_project_is_first_launch"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isFirstLaunch: Bool {
        get {
            if userDefaults.object(forKey: firstLaunchKey) == nil {
                return true
            }
            return userDefaults.bool(forKey: firstLaunchKey)
        }
        set {
            userDefaults.set(newValue, forKey: firstLaunchKey)
        }
    }

    func initializeFirebase() async -> Bool {
        FirebaseEnvironment.shared.setupFirebase()
        return await withCheckedContinuation { continuation in
            FirebaseEnvironment.shared.fetchConfig {
                continuation.resume(returning: true)
            }
        }
    }
}
