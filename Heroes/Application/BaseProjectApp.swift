//
//  BaseProjectApp.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

@main
struct BaseProjectApp: App {

    init() {
        print("🚀 [BaseProjectApp] Initializing HEROS App & Registering Dependencies...")
        registerDependencies()
        print("✅ [BaseProjectApp] All Dependencies Registered Successfully.")
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.light)
        }
    }

    private func registerDependencies() {
        let container = AppDIContainer.shared

        // 1. Network Layer
        container.register(INetworkClient.self, isSingleton: true) {
            NetworkClient()
        }

        // 2. Repository Layer
        container.register(ISplashRepository.self) {
            SplashRepository()
        }

        container.register(ICreateNoteRepository.self) {
            CreateNoteRepository(networkClient: container.resolve())
        }

        container.register(INoteListRepository.self) {
            NoteListRepository(networkClient: container.resolve())
        }

        container.register(ISOSRepository.self, isSingleton: true) {
            SOSRepository()
        }

        container.register(IDeviceRepository.self, isSingleton: true) {
            DeviceRepository()
        }

        // 3. Service Layer
        container.register(ISplashService.self) {
            SplashService(repository: container.resolve())
        }

        container.register(ICreateNoteService.self) {
            CreateNoteService(repository: container.resolve())
        }

        container.register(INoteListService.self) {
            NoteListService(repository: container.resolve())
        }

        container.register(ISOSService.self, isSingleton: true) {
            SOSService(repository: container.resolve())
        }

        container.register(IDeviceService.self, isSingleton: true) {
            DeviceService(repository: container.resolve())
        }

        // 4. ViewModel Layer
        container.register(SplashViewModel.self) {
            SplashViewModel(splashService: container.resolve())
        }

        container.register(CreateNoteViewModel.self) {
            CreateNoteViewModel(createNoteService: container.resolve())
        }

        container.register(NoteListViewModel.self) {
            NoteListViewModel(noteListService: container.resolve())
        }

        container.register(SOSDashboardViewModel.self) {
            SOSDashboardViewModel(sosService: container.resolve(), deviceService: container.resolve())
        }

        container.register(CommunityMapViewModel.self) {
            CommunityMapViewModel(sosService: container.resolve())
        }

        container.register(DeviceManagementViewModel.self) {
            DeviceManagementViewModel(deviceService: container.resolve(), sosService: container.resolve())
        }

        container.register(SOSSettingsViewModel.self) {
            SOSSettingsViewModel(sosService: container.resolve())
        }

        container.register(WomenHandbookViewModel.self) {
            WomenHandbookViewModel(sosService: container.resolve())
        }
    }
}
