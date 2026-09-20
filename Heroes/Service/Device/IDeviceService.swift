//
//  IDeviceService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol IDeviceService {
    func getConnectedDevice() -> BLEDevice?
    func scanDevices() async throws -> [BLEDevice]
    func pairDevice(code: String) async throws -> BLEDevice
    func disconnect() async throws
    func setLEDState(_ state: DeviceLEDState)
    func pressHoldButton1SOS() async throws -> Bool
    func pressHoldButton1Safe() async throws -> Bool
    func holdButton2Recording() -> Bool
    func releaseButton2Recording() -> AudioRecord?
    func testSiren(isActive: Bool) async throws -> Bool
    func toggleSiren(isActive: Bool) async throws -> Bool
}
