//
//  AppTabNavigationView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/6/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

enum AppRoute: Hashable {
    case devices, settings, recordings, emergencyNetwork, profile, sosChats
    case sosChat(String)
}

/// Each tab owns one stack. Every pushed route hides the bottom tab bar.
struct AppTabNavigationView<Root: View>: View {
    @State private var path: [AppRoute] = []
    private let root: Root

    init(@ViewBuilder root: () -> Root) { self.root = root() }

    var body: some View {
        NavigationStack(path: $path) {
            root
                .toolbar(path.isEmpty ? .visible : .hidden, for: .tabBar)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(route)
                        .modifier(AppDetailNavigationModifier(hasCustomHeader: route.hasCustomHeader))
                }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .devices: DeviceManagementView()
        case .settings: SOSSettingsView()
        case .recordings: OwnerRecordingsView()
        case .emergencyNetwork: EmergencyNetworkView(mode: .manage)
        case .profile: UserProfileView()
        case .sosChats: SOSChatListView()
        case .sosChat(let id): SOSChatView(chatId: id)
        }
    }
}

private extension AppRoute {
    var hasCustomHeader: Bool {
        switch self {
        case .sosChats, .sosChat: true
        default: false
        }
    }
}

private struct AppDetailNavigationModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let hasCustomHeader: Bool

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden()
            .toolbar {
                if !hasCustomHeader {
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .topBarLeading) {
                            AppBackButton { dismiss() }
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            AppBackButton { dismiss() }
                        }
                    }
                }
            }
    }
}
