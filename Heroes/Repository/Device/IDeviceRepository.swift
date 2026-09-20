//
//  IDeviceRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol IDeviceRepository {
    func getConnectedDevice() -> BLEDevice?
    func scanAvailableDevices() async throws -> [BLEDevice]
    func pairDeviceWithCode(serialNumber: String) async throws -> BLEDevice
    func disconnectDevice() async throws
    func updateLEDState(_ state: DeviceLEDState)
    func triggerHardwareButton1SOS() async throws -> Bool
    func triggerHardwareButton1CancelSafe() async throws -> Bool
    func startHardwareButton2Recording() -> Bool
    func stopHardwareButton2Recording() -> AudioRecord?
    func testSiren(isActive: Bool) async throws -> Bool
    func toggleSiren(isActive: Bool) async throws -> Bool
}
