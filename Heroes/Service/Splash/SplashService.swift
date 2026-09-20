//
//  SplashService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class SplashService: ISplashService {
    private let repository: ISplashRepository

    init(repository: ISplashRepository) {
        self.repository = repository
    }

    var isFirstLaunch: Bool {
        repository.isFirstLaunch
    }

    func setupApp() async -> Bool {
        print("🚀 [SplashService] Initializing Firebase logic...")
        let firebaseReady = await repository.initializeFirebase()
        print("✅ [SplashService] Firebase setup completed. Result: \(firebaseReady)")
        return firebaseReady
    }

    func markFirstLaunchHandled() {
        repository.isFirstLaunch = false
    }
}
