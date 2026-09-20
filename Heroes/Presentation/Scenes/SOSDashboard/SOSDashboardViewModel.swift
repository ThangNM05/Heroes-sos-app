//
//  SOSDashboardViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class SOSDashboardViewModel: BaseViewModel, ISOSDashboardViewModel {
    // MARK: - Published Properties
    @Published var isEmergencyActive: Bool = false
    @Published var isCountingDown: Bool = false
    @Published var countdownRemaining: Int = 3
    @Published var isRecordingAudio: Bool = false
    @Published var recordingDurationSeconds: Int = 0
    @Published var isSirenPlaying: Bool = false
    @Published var activeSOSAlert: SOSAlert? = nil
    @Published var connectedDevice: BLEDevice? = nil
    @Published var currentSettings: SOSSettings = SOSSettings()
    @Published var simulatedAudioWaveform: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 0.5, 0.3, 0.7, 0.9, 0.4, 0.6]

    // MARK: - Dependencies
    private let sosService: ISOSService
    private let deviceService: IDeviceService

    // MARK: - Timers
    private var countdownTimer: AnyCancellable?
    private var recordingTimer: AnyCancellable?
    private var waveformTimer: AnyCancellable?

    init(sosService: ISOSService, deviceService: IDeviceService) {
        self.sosService = sosService
        self.deviceService = deviceService
        super.init()
    }

    func loadDashboardData() {
        self.currentSettings = sosService.getSettings()
        self.connectedDevice = deviceService.getConnectedDevice()
        self.activeSOSAlert = sosService.getActiveSOSAlert()
        self.isEmergencyActive = (self.activeSOSAlert != nil)
    }

    func onSOSButtonPressed() {
        guard !isEmergencyActive else { return }

        countdownRemaining = currentSettings.countdownDurationSeconds
        isCountingDown = true

        countdownTimer?.cancel()
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.countdownRemaining > 1 {
                    self.countdownRemaining -= 1
                } else {
                    self.countdownTimer?.cancel()
                    self.isCountingDown = false
                    self.triggerImmediateSOS()
                }
            }
    }

    func cancelCountdown() {
        countdownTimer?.cancel()
        isCountingDown = false
        countdownRemaining = currentSettings.countdownDurationSeconds
    }

    func triggerImmediateSOS() {
        countdownTimer?.cancel()
        isCountingDown = false
        isLoading = true

        Task {
            do {
                // 1. Start Auto Audio Recording if enabled
                if currentSettings.autoRecordAudio {
                    self.startRecording()
                }

                // 2. Start Siren on Hardware device if enabled
                if currentSettings.autoTriggerSiren {
                    _ = try await deviceService.toggleSiren(isActive: true)
                    self.isSirenPlaying = true
                }

                // 3. Create Audio Record Mock payload
                let audioPayload = AudioRecord(
                    id: "REC-\(Int.random(in: 100...999))",
                    title: "Ghi âm hiện trường khẩn cấp",
                    durationSeconds: 15,
                    recordedAt: Date(),
                    fileURL: "https://mock.storage/audio/emergency-live.m4a",
                    isEvidence: true
                )

                // 4. Send SOS to Server with GPS & Audio
                let alert = try await sosService.triggerEmergencySOS(
                    latitude: 21.028511,
                    longitude: 105.854444,
                    address: "Đang ở khu vực Hoàn Kiếm, Hà Nội (Định vị thời gian thực)",
                    initialAudio: audioPayload,
                    isHardwareTriggered: (connectedDevice?.isConnected == true)
                )

                self.activeSOSAlert = alert
                self.isEmergencyActive = true
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func resolveEmergency() {
        guard let alert = activeSOSAlert else { return }
        isLoading = true

        Task {
            do {
                try await sosService.resolveActiveSOS(id: alert.id)
                self.stopRecording()
                _ = try await deviceService.toggleSiren(isActive: false)
                self.isSirenPlaying = false
                self.isEmergencyActive = false
                self.activeSOSAlert = nil
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.handleError(error)
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
        if isRecordingAudio {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecordingAudio = true
        recordingDurationSeconds = 0

        recordingTimer?.cancel()
        recordingTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recordingDurationSeconds += 1
            }

        waveformTimer?.cancel()
        waveformTimer = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.simulatedAudioWaveform = (0..<10).map { _ in CGFloat.random(in: 0.15...1.0) }
            }
    }

    private func stopRecording() {
        isRecordingAudio = false
        recordingTimer?.cancel()
        waveformTimer?.cancel()
    }
}
