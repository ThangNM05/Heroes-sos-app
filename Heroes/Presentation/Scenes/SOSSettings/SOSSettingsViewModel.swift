//
//  SOSSettingsViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class SOSSettingsViewModel: BaseViewModel, ISOSSettingsViewModel {
    @Published var settings: SOSSettings = SOSSettings()
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isSaving: Bool = false
    @Published var saveSuccessToast: Bool = false

    private let sosService: ISOSService

    init(sosService: ISOSService) {
        self.sosService = sosService
        super.init()
    }

    func loadSettingsAndContacts() {
        self.settings = sosService.getSettings()
        Task {
            do {
                self.emergencyContacts = try await sosService.fetchEmergencyContacts()
            } catch {
                self.handleError(error)
            }
        }
    }

    func updateUserRole(_ role: HEROSUserRole) {
        self.settings.userRole = role
        saveSettings()
    }

    func updateRecipientMode(_ mode: SOSRecipientMode) {
        self.settings.recipientMode = mode
        saveSettings()
    }

    func toggleTrusted(id: String) {
        Task {
            do {
                try await sosService.toggleTrusted(id: id)
                self.emergencyContacts = try await sosService.fetchEmergencyContacts()
            } catch {
                self.handleError(error)
            }
        }
    }

    func addContact(name: String, relationship: String, phone: String) {
        guard !name.isEmpty, !phone.isEmpty else { return }
        let nextPriority = (emergencyContacts.map(\.priorityOrder).max() ?? 0) + 1

        let newContact = EmergencyContact(
            id: "EC-\(Int.random(in: 100...999))",
            name: name,
            relationship: relationship.isEmpty ? "Người thân" : relationship,
            phoneNumber: phone,
            avatarUrl: nil,
            priorityOrder: nextPriority,
            isTrusted: true,
            isNotifiedViaSMS: true,
            isNotifiedViaCall: true
        )

        Task {
            do {
                try await sosService.addContact(newContact)
                self.emergencyContacts = try await sosService.fetchEmergencyContacts()
            } catch {
                self.handleError(error)
            }
        }
    }

    func deleteContact(id: String) {
        Task {
            do {
                try await sosService.deleteContact(id: id)
                self.emergencyContacts = try await sosService.fetchEmergencyContacts()
            } catch {
                self.handleError(error)
            }
        }
    }

    func saveSettings() {
        sosService.updateSettings(settings)
        saveSuccessToast = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.saveSuccessToast = false
        }
    }
}
