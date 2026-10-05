import Foundation

@MainActor
protocol ICommunityMapViewModel: AnyObject {
    func loadAlerts(for role: HEROSUserRole, currentUser: HEROSAccount?, session: AppSessionStore)
    func triggerSOS(currentUser: HEROSAccount?, session: AppSessionStore)
    func resolveOwnSOS(session: AppSessionStore)
    func respondToAlert(mode: SOSSupportMode, session: AppSessionStore)
    func reconnectRealtime(session: AppSessionStore)
    func disconnectRealtime()
    func stopAudio()
    func clearSelection()
}
