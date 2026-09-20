//
//  SOSDashboardView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSDashboardView: View {
    @StateObject private var viewModel: SOSDashboardViewModel
    @State private var isPulseAnimating = false

    init(viewModel: SOSDashboardViewModel? = nil) {
        let vm = viewModel ?? SOSDashboardViewModel(
            sosService: AppDIContainer.shared.resolve(),
            deviceService: AppDIContainer.shared.resolve()
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - 1. Connected Hardware Device Status Banner
                        deviceStatusHeader

                        // MARK: - 2. Active Emergency Banner (if active)
                        if viewModel.isEmergencyActive {
                            activeEmergencyBanner
                        }

                        // MARK: - 3. Target Recipient Info Pill
                        recipientModePill

                        // MARK: - 4. Center Big SOS Button
                        sosCenterButtonSection
                            .padding(.vertical, 10)

                        // MARK: - 5. Secondary Emergency Triggers (Siren & Audio Evidence)
                        emergencyActionsGrid

                        // MARK: - 6. Live Evidence Recording Box
                        if viewModel.isRecordingAudio {
                            liveAudioRecordingSection
                        }

                        // MARK: - 7. Safe Tips
                        safetyTipsCard

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }

                // MARK: - 8. Countdown Modal Overlay
                if viewModel.isCountingDown {
                    countdownOverlay
                }
            }
            .navigationTitle("Khẩn Cấp SOS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadDashboardData()
                isPulseAnimating = true
            }
        }
    }

    // MARK: - Subviews

    private var deviceStatusHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(viewModel.connectedDevice?.isConnected == true ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.connectedDevice?.isConnected == true ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(viewModel.connectedDevice?.name ?? "Chưa kết nối thiết bị")
                        .font(Theme.Fonts.bold.swiftUI(size: 15))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    if viewModel.connectedDevice?.isConnected == true {
                        Text("• Đã ghép nối")
                            .font(Theme.Fonts.medium.swiftUI(size: 12))
                            .foregroundColor(.green)
                    }
                }

                HStack(spacing: 10) {
                    Label("\(viewModel.connectedDevice?.batteryPercentage ?? 0)%", systemImage: "battery.75")
                        .font(Theme.Fonts.regular.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textSecondaryColor)

                    Text("|")
                        .foregroundColor(Theme.Colors.textSecondaryColor.opacity(0.4))

                    Label("Còi \(viewModel.connectedDevice?.sirenDecibels ?? 110)dB", systemImage: "speaker.wave.3.fill")
                        .font(Theme.Fonts.regular.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }
            }

            Spacer()

            NavigationLink(destination: DeviceManagementView()) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var activeEmergencyBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isPulseAnimating ? 1.3 : 0.8)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulseAnimating)

                    Text("ĐANG PHÁT TÍN HIỆU SOS KHẨN CẤP")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(.red)
                }

                Spacer()

                Text("GPS + Ghi âm")
                    .font(Theme.Fonts.semiBold.swiftUI(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12))
                    .foregroundColor(.red)
                    .cornerRadius(8)
            }

            if let alert = viewModel.activeSOSAlert {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 13))
                        Text(alert.addressName)
                            .font(Theme.Fonts.regular.swiftUI(size: 13))
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .foregroundColor(.red)
                            .font(.system(size: 13))
                        Text("Bản ghi âm bằng chứng đang được lưu trữ và truyền trực tiếp")
                            .font(Theme.Fonts.regular.swiftUI(size: 12))
                            .foregroundColor(Theme.Colors.textSecondaryColor)
                    }
                }
            }

            Button(action: {
                viewModel.resolveEmergency()
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                    Text("TÔI ĐÃ AN TOÀN / HỦY BÁO ĐỘNG")
                        .font(Theme.Fonts.bold.swiftUI(size: 14))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
        )
        .cornerRadius(16)
    }

    private var recipientModePill: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.currentSettings.recipientMode.iconName)
                .foregroundColor(Theme.Colors.primaryColor)

            Text("Phạm vi gửi:")
                .font(Theme.Fonts.regular.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textSecondaryColor)

            Text(viewModel.currentSettings.recipientMode.shortTitle)
                .font(Theme.Fonts.bold.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.primaryColor)

            Spacer()

            NavigationLink(destination: SOSSettingsView()) {
                Text("Đổi")
                    .font(Theme.Fonts.semiBold.swiftUI(size: 13))
                    .foregroundColor(Theme.Colors.primaryColor)
                    .underline()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
    }

    private var sosCenterButtonSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Radar Pulse Rings
                if viewModel.isEmergencyActive {
                    Circle()
                        .stroke(Color.red.opacity(0.25), lineWidth: 3)
                        .frame(width: 260, height: 260)
                        .scaleEffect(isPulseAnimating ? 1.2 : 0.9)
                        .opacity(isPulseAnimating ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulseAnimating)

                    Circle()
                        .stroke(Color.red.opacity(0.35), lineWidth: 2)
                        .frame(width: 220, height: 220)
                        .scaleEffect(isPulseAnimating ? 1.15 : 0.95)
                        .opacity(isPulseAnimating ? 0.2 : 0.9)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.4), value: isPulseAnimating)
                }

                // Shadow ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: viewModel.isEmergencyActive ? [Color.red, Color(hex: "#B71C1C")] : [Color(hex: "#FF5252"), Color(hex: "#D32F2F")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.red.opacity(0.45), radius: 20, x: 0, y: 10)

                // SOS Trigger Button
                Button(action: {
                    viewModel.onSOSButtonPressed()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)

                        Text("SOS")
                            .font(Theme.Fonts.extraBold.swiftUI(size: 32))
                            .foregroundColor(.white)
                            .tracking(2)

                        Text(viewModel.isEmergencyActive ? "ĐANG CẦU CỨU" : "BẤM ĐỂ CẦU CỨU")
                            .font(Theme.Fonts.bold.swiftUI(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 180, height: 180)
                }
            }

            Text("Gửi đồng thời: Tọa độ GPS + Bản ghi âm đối tượng")
                .font(Theme.Fonts.medium.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
    }

    private var emergencyActionsGrid: some View {
        HStack(spacing: 14) {
            // Siren 100dB Button
            Button(action: {
                viewModel.toggleSiren()
            }) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isSirenPlaying ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: viewModel.isSirenPlaying ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(viewModel.isSirenPlaying ? .orange : Theme.Colors.textPrimaryColor)
                    }

                    Text(viewModel.isSirenPlaying ? "Tắt Còi Hú" : "Còi Hú >100dB")
                        .font(Theme.Fonts.bold.swiftUI(size: 14))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text(viewModel.isSirenPlaying ? "Đang hú còi lớn" : "Kích hoạt tức thì")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            }

            // Audio Record Evidence Button
            Button(action: {
                viewModel.toggleAudioRecording()
            }) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecordingAudio ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: viewModel.isRecordingAudio ? "stop.fill" : "mic.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(viewModel.isRecordingAudio ? .red : Theme.Colors.textPrimaryColor)
                    }

                    Text(viewModel.isRecordingAudio ? "Dừng Ghi Âm" : "Ghi Âm Bằng Chứng")
                        .font(Theme.Fonts.bold.swiftUI(size: 14))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text(viewModel.isRecordingAudio ? "\(viewModel.recordingDurationSeconds)s • Đang thu" : "Thu âm kẻ xấu")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            }
        }
    }

    private var liveAudioRecordingSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)

                    Text("ĐANG GHI ÂM ĐỐI THOẠI LÀM BẰNG CHỨNG")
                        .font(Theme.Fonts.bold.swiftUI(size: 12))
                        .foregroundColor(.red)
                }

                Spacer()

                Text(String(format: "%02d:%02d", viewModel.recordingDurationSeconds / 60, viewModel.recordingDurationSeconds % 60))
                    .font(Theme.Fonts.bold.swiftUI(size: 13))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            // Live Waveform Visualizer
            HStack(spacing: 4) {
                ForEach(0..<viewModel.simulatedAudioWaveform.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 4, height: 28 * viewModel.simulatedAudioWaveform[index])
                        .animation(.easeInOut(duration: 0.15), value: viewModel.simulatedAudioWaveform[index])
                }
            }
            .frame(height: 32)

            Text("Tệp ghi âm sẽ tự động mã hoá và lưu trên hệ thống để làm bằng chứng pháp lý.")
                .font(Theme.Fonts.regular.swiftUI(size: 11))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    private var safetyTipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Cơ chế bảo vệ an toàn")
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            Text("1. Nhấn nút trên thiết bị BLE hoặc nút SOS trên app để kích hoạt.\n2. Định vị GPS sẽ được gửi ngay lập tức lên bản đồ cứu hộ.\n3. Micro sẽ tự động ghi lại cuộc đối thoại để gửi kèm tín hiệu cứu hộ.")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("CHUẨN BỊ PHÁT TÍN HIỆU CẦU CỨU")
                    .font(Theme.Fonts.bold.swiftUI(size: 16))
                    .foregroundColor(.white)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.countdownRemaining) / CGFloat(viewModel.currentSettings.countdownDurationSeconds))
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: viewModel.countdownRemaining)

                    Text("\(viewModel.countdownRemaining)")
                        .font(Theme.Fonts.extraBold.swiftUI(size: 56))
                        .foregroundColor(.white)
                }

                Text("Hệ thống sẽ gửi vị trí GPS + Bật ghi âm đối tượng đến \(viewModel.currentSettings.recipientMode.shortTitle)")
                    .font(Theme.Fonts.medium.swiftUI(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.cancelCountdown()
                    }) {
                        Text("HỦY BÁO ĐỘNG")
                            .font(Theme.Fonts.bold.swiftUI(size: 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.triggerImmediateSOS()
                    }) {
                        Text("GỬI NGAY")
                            .font(Theme.Fonts.bold.swiftUI(size: 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(24)
            .background(Color(hex: "#1E293B"))
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Hex Color Helper Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
