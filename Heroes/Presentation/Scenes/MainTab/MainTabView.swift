import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: AppSessionStore

    var body: some View {
        Group {
            if session.currentRole == .deviceOwner { ownerTabs } else { trustedContactTabs }
        }
        .tint(Theme.Colors.primaryColor)
    }

    private var ownerTabs: some View {
        TabView {
            CommunityMapView()
                .tabItem { Label("Bản đồ", systemImage: "map.fill") }
            OwnerRecordingsView()
                .tabItem { Label("Bản ghi", systemImage: "waveform") }
            DeviceManagementView()
                .tabItem { Label("Thiết bị", systemImage: "sensor.tag.radiowaves.forward.fill") }
            SOSSettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
    }

    private var trustedContactTabs: some View {
        TabView {
            CommunityMapView()
                .tabItem { Label("Bản đồ", systemImage: "map.fill") }
            EmergencyNetworkView(mode: .connections)
                .tabItem { Label("Người thân", systemImage: "person.2.fill") }
            SOSSettingsView()
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    MainTabView().environmentObject(AppSessionStore())
}
