import Combine
import CoreLocation
import Foundation

@MainActor
final class SOSDashboardViewModel: BaseViewModel, ISOSDashboardViewModel {
    @Published var isEmergencyActive = false
    @Published var isCountingDown = false
    @Published var countdownRemaining = 3
    @Published var isRecordingAudio = false
    @Published var recordingDurationSeconds = 0
    @Published var isSirenPlaying = false
    @Published var activeSOSAlert: SOSAlert?
    @Published var connectedDevice: BLEDevice?
    @Published var currentSettings = SOSSettings()
    @Published var audioWaveform: [CGFloat] = Array(repeating: 0.08, count: 10)

    private let sosService: ISOSService
    private let deviceService: IDeviceService
    private let repository: ISOSAPIRepository
    private let locationProvider: SOSLocationProvider
    private let audioRecorder: SOSAudioRecorder
    private weak var session: AppSessionStore?
    private var latestLocation: CLLocation?
    private var lastLocationUploadAt: Date?
    private var countdownTimer: AnyCancellable?
    private var recordingTimer: AnyCancellable?
    private var waveformTimer: AnyCancellable?

    init(
        sosService: ISOSService,
        deviceService: IDeviceService,
        repository: ISOSAPIRepository,
        locationProvider: SOSLocationProvider? = nil,
        audioRecorder: SOSAudioRecorder? = nil
    ) {
        self.sosService = sosService
        self.deviceService = deviceService
        self.repository = repository
        self.locationProvider = locationProvider ?? SOSLocationProvider()
        self.audioRecorder = audioRecorder ?? SOSAudioRecorder()
        super.init()
        self.locationProvider.onLocation = { [weak self] location in self?.receive(location) }
    }

    func loadDashboardData(session: AppSessionStore) {
        self.session = session
        currentSettings = sosService.getSettings()
        connectedDevice = deviceService.getConnectedDevice()
        locationProvider.start()
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                activeSOSAlert = try await session.performAuthenticatedRequest {
                    try await self.repository.fetchOwnerActiveSOS(accessToken: $0)
                }
                isEmergencyActive = activeSOSAlert != nil
            } catch {
                handleError(error)
            }
        }
    }

    func stop() {
        locationProvider.stop()
    }

    func onSOSButtonPressed() {
        guard !isEmergencyActive, !isLoading else { return }
        countdownRemaining = currentSettings.countdownDurationSeconds
        isCountingDown = true
        countdownTimer?.cancel()
        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if countdownRemaining > 1 {
                    countdownRemaining -= 1
                } else {
                    cancelCountdownTimerOnly()
                    triggerImmediateSOS()
                }
            }
    }

    func cancelCountdown() {
        cancelCountdownTimerOnly()
        countdownRemaining = currentSettings.countdownDurationSeconds
    }

    func triggerImmediateSOS() {
        cancelCountdownTimerOnly()
        guard let session else {
            errorMessage = AuthValidationError.noActiveSession.localizedDescription
            return
        }
        guard let location = latestLocation ?? locationProvider.latestLocation else {
            errorMessage = "Chưa lấy được vị trí hiện tại. Hãy bật quyền Vị trí và thử lại."
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let update = SOSLocationUpdate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    accuracy: location.horizontalAccuracy,
                    recordedAt: location.timestamp,
                    address: nil
                )
                let alert = try await session.performAuthenticatedRequest {
                    try await self.repository.createSOS(
                        location: update,
                        message: "Tôi đang gặp sự cố, cần hỗ trợ!",
                        clientRequestId: UUID().uuidString.lowercased(),
                        accessToken: $0
                    )
                }
                activeSOSAlert = alert
                isEmergencyActive = true
                if currentSettings.autoRecordAudio { await beginRecording() }
                if currentSettings.autoTriggerSiren {
                    _ = try await deviceService.toggleSiren(isActive: true)
                    isSirenPlaying = true
                }
            } catch let error as APIError where error.serverCode == "SOS_ALREADY_ACTIVE" {
                activeSOSAlert = try? await session.performAuthenticatedRequest {
                    try await self.repository.fetchOwnerActiveSOS(accessToken: $0)
                }
                isEmergencyActive = activeSOSAlert != nil
            } catch {
                handleError(error)
            }
        }
    }

    func resolveEmergency() {
        guard let session, let alert = activeSOSAlert else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if isRecordingAudio { try await finishRecordingAndUpload() }
                try await session.performAuthenticatedRequest {
                    try await self.repository.resolve(sosId: alert.id, accessToken: $0)
                }
                _ = try? await deviceService.toggleSiren(isActive: false)
                isSirenPlaying = false
                isEmergencyActive = false
                activeSOSAlert = nil
            } catch {
                handleError(error)
            }
        }
    }

    func toggleSiren() {
        Task {
            let nextState = !isSirenPlaying
            _ = try? await deviceService.toggleSiren(isActive: nextState)
            self.isSirenPlaying = nextState
        }
    }

    func toggleAudioRecording() {
        guard isEmergencyActive else {
            errorMessage = "Bạn chỉ có thể gửi bản ghi khi một phiên SOS đang hoạt động."
            return
        }
        Task {
            do {
                if isRecordingAudio { try await finishRecordingAndUpload() }
                else { await beginRecording() }
            } catch {
                handleError(error)
            }
        }
    }

    private func beginRecording() async {
        do {
            try await audioRecorder.start()
            isRecordingAudio = true
            recordingDurationSeconds = 0
            startRecordingTimers()
        } catch {
            handleError(error)
        }
    }

    private func finishRecordingAndUpload() async throws {
        guard let session, let sosId = activeSOSAlert?.id else { throw AuthValidationError.noActiveSession }
        stopRecordingTimers()
        isRecordingAudio = false
        let clip = try audioRecorder.stop()
        let uploaded = try await session.performAuthenticatedRequest {
            try await self.repository.uploadRecording(
                sosId: sosId,
                data: clip.data,
                durationSeconds: clip.durationSeconds,
                fileName: clip.fileName,
                mimeType: clip.mimeType,
                accessToken: $0
            )
        }
        activeSOSAlert?.audioRecords.append(uploaded)
    }

    private func startRecordingTimers() {
        recordingTimer?.cancel()
        recordingTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                recordingDurationSeconds += 1
                if recordingDurationSeconds >= 120 {
                    Task {
                        do { try await self.finishRecordingAndUpload() }
                        catch { self.handleError(error) }
                    }
                }
            }
        waveformTimer?.cancel()
        waveformTimer = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let level = audioRecorder.normalizedPowerLevel()
                audioWaveform.removeFirst()
                audioWaveform.append(level)
            }
    }

    private func stopRecordingTimers() {
        recordingTimer?.cancel()
        waveformTimer?.cancel()
        recordingTimer = nil
        waveformTimer = nil
    }

    private func cancelCountdownTimerOnly() {
        countdownTimer?.cancel()
        countdownTimer = nil
        isCountingDown = false
    }

    private func receive(_ location: CLLocation) {
        latestLocation = location
        guard let session, let sosId = activeSOSAlert?.id,
              Date().timeIntervalSince(lastLocationUploadAt ?? .distantPast) >= 10 else { return }
        lastLocationUploadAt = Date()
        let update = SOSLocationUpdate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            recordedAt: location.timestamp,
            address: nil
        )
        Task {
            do {
                activeSOSAlert = try await session.performAuthenticatedRequest {
                    try await self.repository.updateLocation(sosId: sosId, location: update, accessToken: $0)
                }
            } catch {
                handleError(error)
            }
        }
    }
}
