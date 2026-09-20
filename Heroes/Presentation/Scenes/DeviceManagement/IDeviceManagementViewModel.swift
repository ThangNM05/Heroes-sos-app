//
//  IDeviceManagementViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol IDeviceManagementViewModel: AnyObject {
    var connectedDevice: BLEDevice? { get }
    var availableDevices: [BLEDevice] { get }
    var isScanning: Bool { get }
    var isTestingSiren: Bool { get }
    var isHoldingButton1: Bool { get }
    var button1HoldProgress: Double { get }
    var isHoldingButton2: Bool { get }
    var button2RecordDuration: Int { get }

    func loadDeviceData()
    func startScan()
    func pairDevice(code: String)
    func disconnectDevice()
    func startHoldButton1()
    func cancelHoldButton1()
    func startHoldButton2()
    func releaseHoldButton2()
    func testSirenAlarm()
}
