//
//  CommunityMapView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI
import MapKit

struct CommunityMapView: View {
    @StateObject private var viewModel: CommunityMapViewModel
    @State private var showingDetailSheet = false
    @State private var showingReportSheet = false
    @State private var selectedReportReason: FalseAlarmReport.ReportReason = .prank
    @State private var reportNote = ""

    init(viewModel: CommunityMapViewModel? = nil) {
        let vm = viewModel ?? CommunityMapViewModel(sosService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MARK: - 1. Interactive Map with Red "SOS" Markers
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.alerts) { alert in
                    MapAnnotation(coordinate: alert.coordinate) {
                        Button(action: {
                            viewModel.selectAlert(alert)
                            showingDetailSheet = true
                        }) {
                            VStack(spacing: 3) {
                                ZStack {
                                    // Pulse ring for active alert
                                    Circle()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 6)
                                        .frame(width: 48, height: 48)

                                    Circle()
                                        .fill(
                                            alert.status == .active ? Theme.Colors.redColor :
                                            (alert.status == .responding ? Theme.Colors.amberColor : Theme.Colors.greenColor)
                                        )
                                        .frame(width: 38, height: 38)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                                    Text("SOS")
                                        .font(Theme.Fonts.extraBold.swiftUI(size: 12))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                }

                                Text(alert.senderName.components(separatedBy: " ").first ?? "Cứu Hộ")
                                    .font(Theme.Fonts.bold.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2)
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)

                // MARK: - 2. Bottom Sliding Alert Feeds
                VStack(spacing: 12) {
                    // Top Bar Handle & Title
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.Colors.primaryColor)
                                .frame(width: 8, height: 8)

                            Text("Tín Hiệu Cứu Hộ Lân Cận (\(viewModel.alerts.count))")
                                .font(Theme.Fonts.bold.swiftUI(size: 15))
                                .foregroundColor(Theme.Colors.textPrimaryColor)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.loadCommunityAlerts()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.primaryColor)
                                .padding(6)
                                .background(Theme.Colors.softPink)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    // Horizontal Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.alerts) { alert in
                                alertCardView(alert)
                                    .onTapGesture {
                                        viewModel.selectAlert(alert)
                                        showingDetailSheet = true
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
                )

                // MARK: - 3. Action Toast Message
                if let toast = viewModel.actionToastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.white)
                            Text(toast)
                                .font(Theme.Fonts.bold.swiftUI(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.textPrimaryColor.opacity(0.92))
                        .cornerRadius(20)
                        .padding(.bottom, 140)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.actionToastMessage)
                }
            }
            .navigationTitle("HEROS Cứu Hộ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text("HEROS NETWORK")
                            .font(Theme.Fonts.bold.swiftUI(size: 16))
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadCommunityAlerts()
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let alert = viewModel.selectedAlert {
                    alertDetailSheet(alert)
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                reportFalseAlarmSheet
            }
        }
    }

    // MARK: - Subviews

    private func alertCardView(_ alert: SOSAlert) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(alert.status == .active ? Theme.Colors.redColor : (alert.status == .responding ? Theme.Colors.amberColor : Theme.Colors.greenColor))
                        .frame(width: 7, height: 7)

                    Text(alert.status.rawValue)
                        .font(Theme.Fonts.bold.swiftUI(size: 11))
                        .foregroundColor(alert.status == .active ? Theme.Colors.redColor : (alert.status == .responding ? Theme.Colors.amberColor : Theme.Colors.greenColor))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (alert.status == .active ? Theme.Colors.redColor : (alert.status == .responding ? Theme.Colors.amberColor : Theme.Colors.greenColor)).opacity(0.12)
                )
                .cornerRadius(6)

                Spacer()

                if let distance = alert.distanceInMeters {
                    Text(distance < 1000 ? "\(Int(distance))m" : String(format: "%.1f km", distance / 1000))
                        .font(Theme.Fonts.bold.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.primaryColor)
                }
            }

            Text(alert.senderName)
                .font(Theme.Fonts.bold.swiftUI(size: 14))
                .foregroundColor(Theme.Colors.textPrimaryColor)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(Theme.Colors.secondaryColor)
                    .font(.system(size: 11))
                Text(alert.addressName)
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .lineLimit(1)
            }

            // Responders Count Pill
            HStack(spacing: 4) {
                Image(systemName: "figure.run")
                    .foregroundColor(Theme.Colors.primaryColor)
                    .font(.system(size: 11))
                Text("Hiện có \(alert.respondersCount) người đang đến")
                    .font(Theme.Fonts.bold.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.primaryColor)
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(Color(Theme.Colors.bgColor))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.selectedAlert?.id == alert.id ? Theme.Colors.primaryColor : Color.clear, lineWidth: 1.5)
        )
    }

    private func alertDetailSheet(_ alert: SOSAlert) -> some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 5)
                .padding(.top, 10)

            // Header Victim Info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.softPink)
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.primaryColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.senderName)
                        .font(Theme.Fonts.bold.swiftUI(size: 18))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    HStack(spacing: 8) {
                        Text("Phát lúc: \(alert.timeAgoString)")
                            .font(Theme.Fonts.regular.swiftUI(size: 12))
                            .foregroundColor(Theme.Colors.textSecondaryColor)

                        Text("•")
                            .foregroundColor(.gray)

                        Text("Bán kính: \(Int(alert.currentRadiusMeters))m")
                            .font(Theme.Fonts.medium.swiftUI(size: 12))
                            .foregroundColor(Theme.Colors.primaryColor)
                    }
                }

                Spacer()

                // Report Button
                Button(action: {
                    showingReportSheet = true
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("Báo giả")
                            .font(Theme.Fonts.semiBold.swiftUI(size: 10))
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                }
            }

            // Responders Status Box
            HStack(spacing: 12) {
                Image(systemName: "person.3.sequence.fill")
                    .foregroundColor(Theme.Colors.primaryColor)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hiện đã có \(alert.respondersCount) người đang trên đường đến ứng cứu")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                    Text("Hệ thống tự động điều tiết số lượng người để tránh tụ tập quá đông")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }

                Spacer()
            }
            .padding(12)
            .background(Theme.Colors.softPink)
            .cornerRadius(12)

            // Address Details
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "location.fill")
                    .foregroundColor(Theme.Colors.redColor)
                    .font(.system(size: 16))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Địa chỉ hiện tại của người gặp nạn:")
                        .font(Theme.Fonts.semiBold.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                    Text(alert.addressName)
                        .font(Theme.Fonts.medium.swiftUI(size: 14))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(Theme.Colors.bgColor))
            .cornerRadius(12)

            // Voice Memos Section
            if !alert.audioRecords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bản ghi âm đối thoại / Bằng chứng (\(alert.audioRecords.count))")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    ForEach(alert.audioRecords) { record in
                        HStack(spacing: 12) {
                            Button(action: {
                                viewModel.playEvidenceAudio(record: record)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.primaryColor)
                                        .frame(width: 38, height: 38)

                                    Image(systemName: viewModel.isPlayingAudio && viewModel.activeAudioRecord?.id == record.id ? "pause.fill" : "play.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.title)
                                    .font(Theme.Fonts.semiBold.swiftUI(size: 13))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)

                                ProgressView(value: viewModel.isPlayingAudio && viewModel.activeAudioRecord?.id == record.id ? viewModel.audioPlaybackProgress : 0, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.primaryColor))

                                Text("Thời lượng: \(record.formattedDuration)")
                                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .padding(12)
                .background(Color(Theme.Colors.bgColor))
                .cornerRadius(12)
            }

            Spacer()

            // 2 Decision Buttons: "Tôi sẵn sàng ứng cứu" vs "Tôi không thể"
            HStack(spacing: 12) {
                // Button 1: Decline
                Button(action: {
                    viewModel.respondToAlert(isAccepting: false)
                    showingDetailSheet = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Tôi không thể")
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.secondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(14)
                }

                // Button 2: Accept
                Button(action: {
                    viewModel.respondToAlert(isAccepting: true)
                }) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Tôi sẵn sàng ứng cứu")
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.primaryColor)
                    .cornerRadius(14)
                    .shadow(color: Theme.Colors.primaryColor.opacity(0.35), radius: 8, x: 0, y: 3)
                }
            }
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }

    private var reportFalseAlarmSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Báo cáo trường hợp này nếu bạn nghi ngờ đây là báo động đùa giỡn hoặc khi đến nơi không thấy ai. Vi phạm quá 3 lần sẽ bị khoá tính năng cảnh báo trong 30 ngày.")
                    .font(Theme.Fonts.regular.swiftUI(size: 13))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lý do báo cáo:")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    ForEach(FalseAlarmReport.ReportReason.allCases) { reason in
                        Button(action: {
                            selectedReportReason = reason
                        }) {
                            HStack {
                                Image(systemName: selectedReportReason == reason ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(selectedReportReason == reason ? Theme.Colors.primaryColor : .gray)
                                Text(reason.rawValue)
                                    .font(Theme.Fonts.medium.swiftUI(size: 13))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(Theme.Colors.bgColor))
                            .cornerRadius(10)
                        }
                    }
                }

                TextField("Mô tả thêm tình trạng thực tế tại hiện trường...", text: $reportNote)
                    .padding()
                    .background(Color(Theme.Colors.bgColor))
                    .cornerRadius(10)

                Spacer()

                Button(action: {
                    viewModel.submitReport(reason: selectedReportReason, note: reportNote)
                    showingReportSheet = false
                }) {
                    Text("Gửi Báo Cáo Xác Minh")
                        .font(Theme.Fonts.bold.swiftUI(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .navigationTitle("Báo Cáo Báo Động Giả")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        showingReportSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
