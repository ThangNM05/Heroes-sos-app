//
//  ICommunityMapViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import MapKit

protocol ICommunityMapViewModel: AnyObject {
    var alerts: [SOSAlert] { get }
    var selectedAlert: SOSAlert? { get }
    var region: MKCoordinateRegion { get set }
    var isPlayingAudio: Bool { get }
    var activeAudioRecord: AudioRecord? { get }
    var isRespondingSuccess: Bool { get }

    func loadCommunityAlerts()
    func selectAlert(_ alert: SOSAlert)
    func clearSelection()
    func respondToAlert(isAccepting: Bool)
    func submitReport(reason: FalseAlarmReport.ReportReason, note: String)
    func playEvidenceAudio(record: AudioRecord)
    func stopAudio()
}
