//
//  ISOSSettingsViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ISOSSettingsViewModel: AnyObject {
    var settings: SOSSettings { get set }
    var emergencyContacts: [EmergencyContact] { get }
    var isSaving: Bool { get }

    func loadSettingsAndContacts()
    func updateUserRole(_ role: HEROSUserRole)
    func updateRecipientMode(_ mode: SOSRecipientMode)
    func toggleTrusted(id: String)
    func addContact(name: String, relationship: String, phone: String)
    func deleteContact(id: String)
    func saveSettings()
}
