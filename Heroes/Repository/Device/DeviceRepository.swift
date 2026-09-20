//
//  DeviceRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class DeviceRepository: IDeviceRepository {
    private var connectedDevice: BLEDevice? = BLEDevice(
        id: "HEROS-TAG-01",
        name: "HEROS Shield Smart Tag",
        model: "HEROS-V2-PRO",
        serialNumber: "HRS-8839-VN",
        batteryPercentage: 88,
        estimatedRemainingDays: 14,
        isConnected: true,
        sirenDecibels: 110,
        firmwareVersion: "v2.6.0",
        ledState: .off,
        isSirenActive: false,
        lastSyncDate: Date()
    )

    private var availableMockDevices: [BLEDevice] = [
        BLEDevice(
            id: "HEROS-TAG-01",
            name: "HEROS Shield Smart Tag",
            model: "HEROS-V2-PRO",
            serialNumber: "HRS-8839-VN",
            batteryPercentage: 88,
            estimatedRemainingDays: 14,
            isConnected: true,
            sirenDecibels: 110,
            firmwareVersion: "v2.6.0",
            ledState: .off,
            isSirenActive: false,
            lastSyncDate: Date()
        ),
        BLEDevice(
            id: "HEROS-TAG-02",
            name: "HEROS Rose Charm",
            model: "HEROS-CHARM-V1",
            serialNumber: "HRS-5521-VN",
            batteryPercentage: 65,
            estimatedRemainingDays: 9,
            isConnected: false,
            sirenDecibels: 105,
            firmwareVersion: "v1.9.2",
            ledState: .off,
            isSirenActive: false,
            lastSyncDate: Date().addingTimeInterval(-86400)
        )
    ]

    private var recordStartTime: Date?

    init() {}

    func getConnectedDevice() -> BLEDevice? {
        return connectedDevice
    }

    func scanAvailableDevices() async throws -> [BLEDevice] {
        try? await Task.sleep(nanoseconds: 600_000_000)
        return availableMockDevices
    }

    func pairDeviceWithCode(serialNumber: String) async throws -> BLEDevice {
        try? await Task.sleep(nanoseconds: 700_000_000)
        let cleaned = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        let device = BLEDevice(
            id: "HEROS-\(cleaned.isEmpty ? "DEVICE" : cleaned)",
            name: "HEROS Shield Tag (\(cleaned.isEmpty ? "Mới" : cleaned))",
            model: "HEROS-V2-PRO",
            serialNumber: cleaned.isEmpty ? "HRS-CUSTOM-VN" : cleaned,
            batteryPercentage: 100,
            estimatedRemainingDays: 18,
            isConnected: true,
            sirenDecibels: 110,
            firmwareVersion: "v2.6.0",
            ledState: .off,
            isSirenActive: false,
            lastSyncDate: Date()
        )

        self.connectedDevice = device
        return device
    }

    func disconnectDevice() async throws {
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.connectedDevice?.isConnected = false
        self.connectedDevice = nil
    }

    func updateLEDState(_ state: DeviceLEDState) {
        self.connectedDevice?.ledState = state
    }

    func triggerHardwareButton1SOS() async throws -> Bool {
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.connectedDevice?.ledState = .sosActiveRed
        return true
    }

    func triggerHardwareButton1CancelSafe() async throws -> Bool {
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.connectedDevice?.ledState = .off
        self.connectedDevice?.isSirenActive = false
        return true
    }

    func startHardwareButton2Recording() -> Bool {
        self.connectedDevice?.ledState = .recordingYellow
        self.recordStartTime = Date()
        return true
    }

    func stopHardwareButton2Recording() -> AudioRecord? {
        if var device = self.connectedDevice {
            if device.ledState == .recordingYellow {
                device.ledState = .off
            }
            self.connectedDevice = device
        }

        let duration = max(3, Int(Date().timeIntervalSince(self.recordStartTime ?? Date())))
        let record = AudioRecord(
            id: "REC-\(Int.random(in: 100...999))",
            title: "Voice Memo HEROS #\(Int.random(in: 10...99))",
            durationSeconds: duration,
            recordedAt: Date(),
            fileURL: "https://mock.storage/audio/voice-memo-\(Int.random(in: 100...999)).m4a",
            isEvidence: true
        )
        self.recordStartTime = nil
        return record
    }

    func testSiren(isActive: Bool) async throws -> Bool {
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.connectedDevice?.isSirenActive = isActive
        return isActive
    }

    func toggleSiren(isActive: Bool) async throws -> Bool {
        return try await testSiren(isActive: isActive)
    }
}
