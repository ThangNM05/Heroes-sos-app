//
//  ISOSRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

protocol ISOSRepository {
    func getSOSSettings() -> SOSSettings
    func updateSOSSettings(_ settings: SOSSettings)
    func triggerSOS(latitude: Double, longitude: Double, address: String, initialAudio: AudioRecord?, isHardwareTriggered: Bool) async throws -> SOSAlert
    func resolveActiveSOS(id: String) async throws
    func getActiveSOSAlert() -> SOSAlert?
    func getCommunitySOSAlerts() async throws -> [SOSAlert]
    func respondToSOS(alertId: String, isAccepting: Bool) async throws -> SOSAlert
    func appendVoiceMemo(alertId: String, record: AudioRecord) async throws
    func submitFalseAlarmReport(_ report: FalseAlarmReport) async throws
    func getEmergencyContacts() async throws -> [EmergencyContact]
    func addEmergencyContact(_ contact: EmergencyContact) async throws
    func deleteEmergencyContact(id: String) async throws
    func toggleTrustedContact(id: String) async throws
    func getHandbookArticles() async throws -> [HandbookArticle]
}
