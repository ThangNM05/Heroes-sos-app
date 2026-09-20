//
//  SplashViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class SplashViewModel: BaseViewModel, ISplashViewModel {
    @Published var progress: Double = 0.0
    @Published var isCompleted: Bool = false

    private let splashService: ISplashService

    init(splashService: ISplashService) {
        self.splashService = splashService
        super.init()
    }

    func startSplashFlow() async {
        print("🎬 [SplashViewModel] Starting Splash flow...")
        isLoading = true
        progress = 0.1
        defer { isLoading = false }

        // Step 1: Initialize Firebase Logic
        _ = await splashService.setupApp()
        progress = 0.5

        // Step 2: Smooth countdown progress (simulate 1.5 - 2s splash duration)
        for step in 5...10 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 sec
            progress = Double(step) / 10.0
        }

        if splashService.isFirstLaunch {
            splashService.markFirstLaunchHandled()
        }

        print("🎉 [SplashViewModel] Splash flow completed. Navigating to Main Screen...")
        isCompleted = true
    }
}
