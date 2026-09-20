//
//  DeviceService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class DeviceService: IDeviceService {
    private let repository: IDeviceRepository

    init(repository: IDeviceRepository) {
        self.repository = repository
    }

    func getConnectedDevice() -> BLEDevice? {
        return repository.getConnectedDevice()
    }

    func scanDevices() async throws -> [BLEDevice] {
        return try await repository.scanAvailableDevices()
    }

    func pairDevice(code: String) async throws -> BLEDevice {
        return try await repository.pairDeviceWithCode(serialNumber: code)
    }

    func disconnect() async throws {
        try await repository.disconnectDevice()
    }

    func setLEDState(_ state: DeviceLEDState) {
        repository.updateLEDState(state)
    }

    func pressHoldButton1SOS() async throws -> Bool {
        return try await repository.triggerHardwareButton1SOS()
    }

    func pressHoldButton1Safe() async throws -> Bool {
        return try await repository.triggerHardwareButton1CancelSafe()
    }

    func holdButton2Recording() -> Bool {
        return repository.startHardwareButton2Recording()
    }

    func releaseButton2Recording() -> AudioRecord? {
        return repository.stopHardwareButton2Recording()
    }

    func testSiren(isActive: Bool) async throws -> Bool {
        return try await repository.testSiren(isActive: isActive)
    }

    func toggleSiren(isActive: Bool) async throws -> Bool {
        return try await repository.toggleSiren(isActive: isActive)
    }
}
