import Foundation
import Combine
import MapKit

@MainActor
final class CommunityMapViewModel: BaseViewModel, ICommunityMapViewModel {
    @Published var alerts: [SOSAlert] = []
    @Published var selectedAlert: SOSAlert?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.804817),
        span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
    )
    @Published private(set) var activeAudioRecord: AudioRecord?
    @Published private(set) var isPlayingAudio = false
    @Published private(set) var isLoadingAudio = false

    private let sosService: ISOSService
    private let repository: ISOSAPIRepository
    private let realtimeClient: ISOSRealtimeClient
    private let audioPlayer: ProtectedAudioPlayer
    private let locationProvider = SOSLocationProvider()
    private var role: HEROSUserRole = .trustedContact
    private var currentUser: HEROSAccount?
    private weak var session: AppSessionStore?
    private var cancellables = Set<AnyCancellable>()
    private var latestLocation: CLLocation?
    private var lastLocationUploadAt: Date?

    init(
        sosService: ISOSService,
        sosAPIRepository: ISOSAPIRepository,
        realtimeClient: ISOSRealtimeClient,
        audioPlayer: ProtectedAudioPlayer
    ) {
        self.sosService = sosService
        self.repository = sosAPIRepository
        self.realtimeClient = realtimeClient
        self.audioPlayer = audioPlayer
        super.init()
        bindAudioPlayer()
        bindRealtime()
        locationProvider.onLocation = { [weak self] location in
            self?.receive(location)
        }
    }

    func loadAlerts(for role: HEROSUserRole, currentUser: HEROSAccount?, session: AppSessionStore) {
        self.role = role
        self.currentUser = currentUser
        self.session = session
        if role == .deviceOwner { locationProvider.start() }
        reconnectRealtime(session: session)
        reloadFromServer()
    }

    func reloadFromServer() {
        guard let session else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let freshAlerts: [SOSAlert]
                if role == .deviceOwner {
                    let active = try await session.performAuthenticatedRequest {
                        try await self.repository.fetchOwnerActiveSOS(accessToken: $0)
                    }
                    freshAlerts = active.map { [$0] } ?? []
                } else {
                    freshAlerts = try await session.performAuthenticatedRequest {
                        try await self.repository.fetchIncomingSOS(accessToken: $0)
                    }
                }
                apply(freshAlerts)
            } catch {
                handleError(error)
            }
        }
    }

    func triggerSOS(currentUser: HEROSAccount?, session: AppSessionStore) {
        let coordinate = latestLocation?.coordinate ?? region.center
        let location = SOSLocationUpdate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            accuracy: latestLocation?.horizontalAccuracy ?? 0,
            recordedAt: latestLocation?.timestamp ?? Date(),
            address: nil
        )
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let alert = try await session.performAuthenticatedRequest {
                    try await self.repository.createSOS(
                        location: location,
                        message: "Tôi đang gặp sự cố, cần hỗ trợ!",
                        clientRequestId: UUID().uuidString.lowercased(),
                        accessToken: $0
                    )
                }
                self.currentUser = currentUser
                apply([alert])
            } catch let error as APIError where error.serverCode == "SOS_ALREADY_ACTIVE" {
                let active = try? await session.performAuthenticatedRequest {
                    try await self.repository.fetchOwnerActiveSOS(accessToken: $0)
                }
                if let active { self.apply([active]) } else { self.handleError(error) }
            } catch {
                handleError(error)
            }
        }
    }

    func resolveOwnSOS(session: AppSessionStore) {
        guard let alert = alerts.first else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await session.performAuthenticatedRequest {
                    try await self.repository.resolve(sosId: alert.id, accessToken: $0)
                }
                audioPlayer.clearAndStop()
                clearSelection()
                alerts = []
            } catch {
                handleError(error)
            }
        }
    }

    func respondToAlert(mode: SOSSupportMode, session: AppSessionStore) {
        guard let alert = selectedAlert else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                _ = try await session.performAuthenticatedRequest {
                    try await self.repository.acknowledge(sosId: alert.id, mode: mode, accessToken: $0)
                }
                let updated = try await session.performAuthenticatedRequest {
                    try await self.repository.fetchSOS(id: alert.id, accessToken: $0)
                }
                replace(updated)
                if let chatId = updated.chatId { session.openSOSChat(chatId) }
            } catch {
                handleError(error)
            }
        }
    }

    func updateActiveSOSLocation(_ location: SOSLocationUpdate, session: AppSessionStore) {
        guard role == .deviceOwner, let active = alerts.first else { return }
        Task {
            do {
                let updated = try await session.performAuthenticatedRequest {
                    try await self.repository.updateLocation(sosId: active.id, location: location, accessToken: $0)
                }
                replace(updated)
            } catch {
                handleError(error)
            }
        }
    }

    func selectAlert(_ alert: SOSAlert) {
        selectedAlert = alert
    }

    func clearSelection() {
        selectedAlert = nil
    }

    func playEvidenceAudio(record: AudioRecord, session: AppSessionStore) {
        guard let sosId = record.sosId ?? selectedAlert?.id else { return }
        audioPlayer.play(record: record, sosId: sosId, session: session)
    }

    func stopAudio() {
        audioPlayer.stop()
    }

    func stopAudioAndClearCache() {
        audioPlayer.clearAndStop()
    }

    func reconnectRealtime(session: AppSessionStore) {
        guard let token = session.activeAccessToken else {
            realtimeClient.disconnect()
            return
        }
        realtimeClient.connect(accessToken: token)
    }

    func disconnectRealtime() {
        locationProvider.stop()
        audioPlayer.stop()
    }

    func submitReport(_ report: FalseAlarmReport) {
        Task {
            do { try await sosService.reportFalseAlarm(report) }
            catch { handleError(error) }
        }
    }

    private func bindAudioPlayer() {
        audioPlayer.$activeRecordingID
            .combineLatest(audioPlayer.$isPlaying, audioPlayer.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] recordingID, isPlaying, isLoading in
                guard let self else { return }
                activeAudioRecord = alerts
                    .flatMap(\.audioRecords)
                    .first { $0.id == recordingID }
                isPlayingAudio = isPlaying
                isLoadingAudio = isLoading
            }
            .store(in: &cancellables)
    }

    private func bindRealtime() {
        realtimeClient.events.sink { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                switch event {
                case .resolved, .cancelled:
                    self.audioPlayer.clearAndStop()
                default:
                    break
                }
                self.reloadFromServer()
            }
        }.store(in: &cancellables)
    }

    private func apply(_ freshAlerts: [SOSAlert]) {
        alerts = freshAlerts.filter { $0.status != .resolved && $0.status != .cancelled }
        if let selectedID = selectedAlert?.id {
            selectedAlert = alerts.first { $0.id == selectedID }
            if selectedAlert == nil { audioPlayer.clearAndStop() }
        }
        if let first = alerts.first, first.latitude != 0 || first.longitude != 0 {
            region.center = first.coordinate
        }
    }

    private func replace(_ alert: SOSAlert) {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
        } else {
            alerts.insert(alert, at: 0)
        }
        if selectedAlert?.id == alert.id { selectedAlert = alert }
    }

    private func receive(_ location: CLLocation) {
        latestLocation = location
        region.center = location.coordinate
        guard role == .deviceOwner,
              let session,
              !alerts.isEmpty,
              Date().timeIntervalSince(lastLocationUploadAt ?? .distantPast) >= 10 else { return }
        lastLocationUploadAt = Date()
        updateActiveSOSLocation(
            SOSLocationUpdate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                recordedAt: location.timestamp,
                address: nil
            ),
            session: session
        )
    }
}
