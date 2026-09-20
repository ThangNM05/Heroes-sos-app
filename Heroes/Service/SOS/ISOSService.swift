//
//  ISOSService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ISOSService {
    func getSettings() -> SOSSettings
    func updateSettings(_ settings: SOSSettings)
    func triggerEmergencySOS(latitude: Double, longitude: Double, address: String, initialAudio: AudioRecord?, isHardwareTriggered: Bool) async throws -> SOSAlert
    func resolveActiveSOS(id: String) async throws
    func getActiveSOSAlert() -> SOSAlert?
    func fetchCommunityAlerts() async throws -> [SOSAlert]
    func respondToAlert(alertId: String, isAccepting: Bool) async throws -> SOSAlert
    func sendVoiceMemo(alertId: String, record: AudioRecord) async throws
    func reportFalseAlarm(_ report: FalseAlarmReport) async throws
    func fetchEmergencyContacts() async throws -> [EmergencyContact]
    func addContact(_ contact: EmergencyContact) async throws
    func deleteContact(id: String) async throws
    func toggleTrusted(id: String) async throws
    func fetchHandbookArticles() async throws -> [HandbookArticle]
}
