//
//  MainTabView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .map

    enum Tab: Int, CaseIterable {
        case map
        case device
        case handbook
        case settings

        var title: String {
            switch self {
            case .map: return "Bản Đồ"
            case .device: return "Thiết Bị"
            case .handbook: return "Cẩm Nang"
            case .settings: return "Cài Đặt"
            }
        }

        var iconName: String {
            switch self {
            case .map: return "map.fill"
            case .device: return "shield.checkered"
            case .handbook: return "heart.text.square.fill"
            case .settings: return "gearshape.2.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CommunityMapView()
                .tabItem {
                    Label(Tab.map.title, systemImage: Tab.map.iconName)
                }
                .tag(Tab.map)

            DeviceManagementView()
                .tabItem {
                    Label(Tab.device.title, systemImage: Tab.device.iconName)
                }
                .tag(Tab.device)

            WomenHandbookView()
                .tabItem {
                    Label(Tab.handbook.title, systemImage: Tab.handbook.iconName)
                }
                .tag(Tab.handbook)

            SOSSettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .tint(Theme.Colors.primaryColor)
    }
}

#Preview {
    MainTabView()
}
