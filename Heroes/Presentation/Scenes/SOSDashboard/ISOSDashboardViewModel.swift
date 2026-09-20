//
//  ISOSDashboardViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ISOSDashboardViewModel: AnyObject {
    var isEmergencyActive: Bool { get }
    var isCountingDown: Bool { get }
    var countdownRemaining: Int { get }
    var isRecordingAudio: Bool { get }
    var recordingDurationSeconds: Int { get }
    var isSirenPlaying: Bool { get }
    var activeSOSAlert: SOSAlert? { get }
    var connectedDevice: BLEDevice? { get }
    var currentSettings: SOSSettings { get }

    func onSOSButtonPressed()
    func cancelCountdown()
    func triggerImmediateSOS()
    func resolveEmergency()
    func toggleSiren()
    func toggleAudioRecording()
    func loadDashboardData()
}
