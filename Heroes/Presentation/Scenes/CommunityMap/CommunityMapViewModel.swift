//
//  CommunityMapViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import MapKit
import Combine

@MainActor
final class CommunityMapViewModel: BaseViewModel, ICommunityMapViewModel {
    @Published var alerts: [SOSAlert] = []
    @Published var selectedAlert: SOSAlert? = nil
    @Published var isPlayingAudio: Bool = false
    @Published var activeAudioRecord: AudioRecord? = nil
    @Published var audioPlaybackProgress: Double = 0.0
    @Published var isRespondingSuccess: Bool = false
    @Published var actionToastMessage: String? = nil

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    private let sosService: ISOSService
    private var playbackTimer: AnyCancellable?

    init(sosService: ISOSService) {
        self.sosService = sosService
        super.init()
    }

    func loadCommunityAlerts() {
        isLoading = true
        Task {
            do {
                self.alerts = try await sosService.fetchCommunityAlerts()
                if let first = self.alerts.first {
                    self.region.center = first.coordinate
                }
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func selectAlert(_ alert: SOSAlert) {
        self.selectedAlert = alert
        self.region.center = alert.coordinate
    }

    func clearSelection() {
        self.selectedAlert = nil
        stopAudio()
    }

    func respondToAlert(isAccepting: Bool) {
        guard let alert = selectedAlert else { return }
        isLoading = true

        Task {
            do {
                let updated = try await sosService.respondToAlert(alertId: alert.id, isAccepting: isAccepting)
                self.selectedAlert = updated
                self.alerts = try await sosService.fetchCommunityAlerts()
                self.isLoading = false

                if isAccepting {
                    self.isRespondingSuccess = true
                    self.showToast("Cảm ơn bạn! Hệ thống đã ghi nhận bạn là nguồn hỗ trợ và thông báo tới thiết bị nạn nhân.")
                } else {
                    self.showToast("Đã từ chối. Hệ thống tiếp tục mở rộng bán kính tìm người hỗ trợ khác.")
                    self.selectedAlert = nil
                }
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func submitReport(reason: FalseAlarmReport.ReportReason, note: String) {
        guard let alert = selectedAlert else { return }
        isLoading = true

        let report = FalseAlarmReport(
            id: "RPT-\(Int.random(in: 100...999))",
            alertId: alert.id,
            reporterName: "Bạn (Cộng tác viên)",
            reporterPhone: "0900 111 222",
            reason: reason,
            note: note,
            createdAt: Date()
        )

        Task {
            do {
                try await sosService.reportFalseAlarm(report)
                self.isLoading = false
                self.showToast("Đã gửi báo cáo. Tổng đài viên HEROS sẽ xác minh xử lý tài khoản vi phạm.")
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func playEvidenceAudio(record: AudioRecord) {
        if activeAudioRecord?.id == record.id && isPlayingAudio {
            stopAudio()
            return
        }

        activeAudioRecord = record
        isPlayingAudio = true
        audioPlaybackProgress = 0.0

        playbackTimer?.cancel()
        playbackTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.audioPlaybackProgress < 1.0 {
                    self.audioPlaybackProgress += 0.08
                } else {
                    self.stopAudio()
                }
            }
    }

    func stopAudio() {
        isPlayingAudio = false
        playbackTimer?.cancel()
        audioPlaybackProgress = 0.0
    }

    private func showToast(_ message: String) {
        self.actionToastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.actionToastMessage == message {
                self.actionToastMessage = nil
            }
        }
    }
}
