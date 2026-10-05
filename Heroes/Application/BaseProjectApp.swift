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
    @UIApplicationDelegateAdaptor(HEROSAppDelegate.self) private var appDelegate
    @StateObject private var session: AppSessionStore

    init() {
        print("🚀 [BaseProjectApp] Initializing HEROS App & Registering Dependencies...")
        let container = Self.registerDependencies()
        _session = StateObject(
            wrappedValue: AppSessionStore(
                authService: container.resolve(),
                sessionStore: container.resolve(),
                installationIDProvider: container.resolve(),
                emergencyContactsRepository: container.resolve(),
                pendingInviteStore: container.resolve(),
                pushDeviceRepository: container.resolve()
            )
        )
        print("✅ [BaseProjectApp] All Dependencies Registered Successfully.")
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(session)
                .modifier(SOSRealtimeLifecycleModifier())
                .preferredColorScheme(.light)
                .onOpenURL { session.handleInvitationURL($0) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    session.handleInvitationURL(url)
                }
        }
    }

    private static func registerDependencies() -> AppDIContainer {
        let container = AppDIContainer.shared

        // 1. Network Layer
        container.register(INetworkClient.self, isSingleton: true) {
            NetworkClient()
        }

        container.register(AuthSessionStoring.self, isSingleton: true) {
            KeychainAuthSessionStore()
        }

        container.register(InstallationIDProviding.self, isSingleton: true) {
            InstallationIDProvider()
        }

        container.register(PendingInviteCodeStoring.self, isSingleton: true) {
            KeychainPendingInviteCodeStore()
        }

        // 2. Repository Layer
        container.register(ISOSChatRepository.self, isSingleton: true) {
            SOSChatRepository(networkClient: container.resolve())
        }
        container.register(ISOSChatService.self, isSingleton: true) {
            SOSChatService(repository: container.resolve(), sosRepository: container.resolve())
        }
        container.register(IAuthRepository.self, isSingleton: true) {
            AuthRepository(networkClient: container.resolve())
        }

        container.register(IEmergencyContactsRepository.self, isSingleton: true) {
            EmergencyContactsRepository(networkClient: container.resolve())
        }

        container.register(ISOSAPIRepository.self, isSingleton: true) {
            SOSAPIRepository(networkClient: container.resolve())
        }

        container.register(IPushDeviceRepository.self, isSingleton: true) {
            PushDeviceRepository(networkClient: container.resolve())
        }

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
        container.register(IAuthService.self, isSingleton: true) {
            AuthService(repository: container.resolve())
        }

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

        container.register(ISOSRealtimeClient.self, isSingleton: true) {
            SOSRealtimeClient()
        }

        container.register(ProtectedAudioPlayer.self, isSingleton: true) {
            ProtectedAudioPlayer(repository: container.resolve())
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
            SOSDashboardViewModel(
                sosService: container.resolve(),
                deviceService: container.resolve(),
                repository: container.resolve()
            )
        }

        container.register(CommunityMapViewModel.self) {
            CommunityMapViewModel(
                sosService: container.resolve(),
                sosAPIRepository: container.resolve(),
                realtimeClient: container.resolve(),
                audioPlayer: container.resolve()
            )
        }

        container.register(DeviceManagementViewModel.self) {
            DeviceManagementViewModel(deviceService: container.resolve(), sosService: container.resolve())
        }

        container.register(SOSSettingsViewModel.self) {
            SOSSettingsViewModel(
                sosService: container.resolve(),
                emergencyContactsRepository: container.resolve()
            )
        }

        container.register(WomenHandbookViewModel.self) {
            WomenHandbookViewModel(sosService: container.resolve())
        }

        return container
    }
}
