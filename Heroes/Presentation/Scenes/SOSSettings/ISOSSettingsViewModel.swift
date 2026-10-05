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
    var invitations: [EmergencyInvitation] { get }
    var isSaving: Bool { get }

    func loadSettingsAndContacts(session: AppSessionStore, mode: EmergencyNetworkView.Mode)
    func updateUserRole(_ role: HEROSUserRole)
    func updateRecipientMode(_ mode: SOSRecipientMode)
    func saveSettings()
}
