//
//  SOSService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class SOSService: ISOSService {
    private let repository: ISOSRepository

    init(repository: ISOSRepository) {
        self.repository = repository
    }

    func getSettings() -> SOSSettings {
        return repository.getSOSSettings()
    }

    func updateSettings(_ settings: SOSSettings) {
        repository.updateSOSSettings(settings)
    }

    func triggerEmergencySOS(latitude: Double, longitude: Double, address: String, initialAudio: AudioRecord?, isHardwareTriggered: Bool) async throws -> SOSAlert {
        return try await repository.triggerSOS(
            latitude: latitude,
            longitude: longitude,
            address: address,
            initialAudio: initialAudio,
            isHardwareTriggered: isHardwareTriggered
        )
    }

    func resolveActiveSOS(id: String) async throws {
        try await repository.resolveActiveSOS(id: id)
    }

    func getActiveSOSAlert() -> SOSAlert? {
        return repository.getActiveSOSAlert()
    }

    func fetchCommunityAlerts() async throws -> [SOSAlert] {
        return try await repository.getCommunitySOSAlerts()
    }

    func respondToAlert(alertId: String, isAccepting: Bool) async throws -> SOSAlert {
        return try await repository.respondToSOS(alertId: alertId, isAccepting: isAccepting)
    }

    func sendVoiceMemo(alertId: String, record: AudioRecord) async throws {
        try await repository.appendVoiceMemo(alertId: alertId, record: record)
    }

    func reportFalseAlarm(_ report: FalseAlarmReport) async throws {
        try await repository.submitFalseAlarmReport(report)
    }

    func fetchEmergencyContacts() async throws -> [EmergencyContact] {
        return try await repository.getEmergencyContacts()
    }

    func addContact(_ contact: EmergencyContact) async throws {
        try await repository.addEmergencyContact(contact)
    }

    func deleteContact(id: String) async throws {
        try await repository.deleteEmergencyContact(id: id)
    }

    func toggleTrusted(id: String) async throws {
        try await repository.toggleTrustedContact(id: id)
    }

    func fetchHandbookArticles() async throws -> [HandbookArticle] {
        return try await repository.getHandbookArticles()
    }
}
