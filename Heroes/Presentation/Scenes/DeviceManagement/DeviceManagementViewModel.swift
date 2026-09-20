//
//  DeviceManagementViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class DeviceManagementViewModel: BaseViewModel, IDeviceManagementViewModel {
    @Published var connectedDevice: BLEDevice? = nil
    @Published var availableDevices: [BLEDevice] = []
    @Published var isScanning: Bool = false
    @Published var isTestingSiren: Bool = false
    @Published var toastMessage: String? = nil

    // Button 1 (SOS): Nhấn giữ 5s
    @Published var isHoldingButton1: Bool = false
    @Published var button1HoldProgress: Double = 0.0

    // Button 2 (Record): Nhấn giữ để thu âm, thả để gửi
    @Published var isHoldingButton2: Bool = false
    @Published var button2RecordDuration: Int = 0

    private let deviceService: IDeviceService
    private let sosService: ISOSService

    private var button1Timer: AnyCancellable?
    private var button2Timer: AnyCancellable?
    private var sirenTestTimer: AnyCancellable?

    init(deviceService: IDeviceService, sosService: ISOSService) {
        self.deviceService = deviceService
        self.sosService = sosService
        super.init()
    }

    func loadDeviceData() {
        self.connectedDevice = deviceService.getConnectedDevice()
    }

    func startScan() {
        isScanning = true
        Task {
            do {
                self.availableDevices = try await deviceService.scanDevices()
                self.isScanning = false
            } catch {
                self.isScanning = false
                self.handleError(error)
            }
        }
    }

    func pairDevice(code: String) {
        isLoading = true
        Task {
            do {
                self.connectedDevice = try await deviceService.pairDevice(code: code)
                self.isLoading = false
                self.showToast("Ghép nối thiết bị \(self.connectedDevice?.name ?? "") thành công!")
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func disconnectDevice() {
        isLoading = true
        Task {
            do {
                try await deviceService.disconnect()
                self.connectedDevice = nil
                self.isLoading = false
                self.showToast("Đã ngắt kết nối thiết bị.")
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    // MARK: - Nút 1: Nhấn giữ 5s để kích hoạt SOS / Nhấn giữ 5s lại để An toàn
    func startHoldButton1() {
        guard !isHoldingButton1 else { return }
        isHoldingButton1 = true
        button1HoldProgress = 0.0

        let isCurrentlyActive = (connectedDevice?.ledState == .sosActiveRed || connectedDevice?.ledState == .responderIncomingGreen)

        button1Timer?.cancel()
        button1Timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.button1HoldProgress < 1.0 {
                    self.button1HoldProgress += 0.02 // 5 seconds (50 steps of 0.1s)
                } else {
                    self.button1Timer?.cancel()
                    self.isHoldingButton1 = false
                    self.button1HoldProgress = 0.0
                    self.executeButton1Action(wasActive: isCurrentlyActive)
                }
            }
    }

    func cancelHoldButton1() {
        button1Timer?.cancel()
        isHoldingButton1 = false
        button1HoldProgress = 0.0
    }

    private func executeButton1Action(wasActive: Bool) {
        Task {
            if wasActive {
                // Nhấn giữ 5s lại: Xác nhận tôi đã an toàn, đèn tắt
                _ = try? await deviceService.pressHoldButton1Safe()
                if let active = sosService.getActiveSOSAlert() {
                    try? await sosService.resolveActiveSOS(id: active.id)
                }
                self.connectedDevice?.ledState = .off
                self.showToast("Đã xác nhận an toàn! Đèn tắt, kết thúc cảnh báo SOS.")
            } else {
                // Nhấn giữ 5s: Kích hoạt SOS, đèn đỏ + rung
                _ = try? await deviceService.pressHoldButton1SOS()
                _ = try? await sosService.triggerEmergencySOS(
                    latitude: 21.028511,
                    longitude: 105.854444,
                    address: "Khu vực Hoàn Kiếm, Hà Nội (Kích hoạt từ Nút vật lý HEROS)",
                    initialAudio: nil,
                    isHardwareTriggered: true
                )
                self.connectedDevice?.ledState = .sosActiveRed
                self.showToast("ĐÃ KÍCH HOẠT SOS! Đèn ĐỎ sáng + Thiết bị rung phản hồi.")
            }
            self.loadDeviceData()
        }
    }

    // MARK: - Nút 2: Nhấn giữ thu âm, thả tay để gửi
    func startHoldButton2() {
        guard !isHoldingButton2 else { return }
        isHoldingButton2 = true
        button2RecordDuration = 0
        _ = deviceService.holdButton2Recording()
        self.connectedDevice?.ledState = .recordingYellow

        button2Timer?.cancel()
        button2Timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.button2RecordDuration += 1
                if self.button2RecordDuration >= 120 { // tối đa 120s
                    self.releaseHoldButton2()
                }
            }
    }

    func releaseHoldButton2() {
        guard isHoldingButton2 else { return }
        button2Timer?.cancel()
        isHoldingButton2 = false

        let record = deviceService.releaseButton2Recording()
        self.connectedDevice?.ledState = .off

        if let audio = record {
            Task {
                if let active = sosService.getActiveSOSAlert() {
                    try? await sosService.sendVoiceMemo(alertId: active.id, record: audio)
                }
                self.showToast("Đã gửi đoạn ghi âm (\(audio.formattedDuration)) tới nhóm người nhận đã thiết lập!")
                self.loadDeviceData()
            }
        }
    }

    func testSirenAlarm() {
        guard !isTestingSiren else { return }
        isTestingSiren = true

        Task {
            _ = try? await deviceService.testSiren(isActive: true)

            sirenTestTimer?.cancel()
            sirenTestTimer = Timer.publish(every: 3.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.sirenTestTimer?.cancel()
                    Task {
                        _ = try? await self.deviceService.testSiren(isActive: false)
                        self.isTestingSiren = false
                    }
                }
        }
    }

    private func showToast(_ message: String) {
        self.toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.toastMessage == message {
                self.toastMessage = nil
            }
        }
    }
}
