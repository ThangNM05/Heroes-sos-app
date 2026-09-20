//
//  DeviceManagementView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct DeviceManagementView: View {
    @StateObject private var viewModel: DeviceManagementViewModel
    @State private var showingPairSheet = false
    @State private var inputSerialNumber = ""

    init(viewModel: DeviceManagementViewModel? = nil) {
        let vm = viewModel ?? DeviceManagementViewModel(
            deviceService: AppDIContainer.shared.resolve(),
            sosService: AppDIContainer.shared.resolve()
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // MARK: - 1. Connected Device Status Card
                        if let device = viewModel.connectedDevice {
                            connectedDeviceCard(device)
                        } else {
                            noDeviceCard
                        }

                        // MARK: - 2. Physical 2-Button Interactive Simulator
                        if viewModel.connectedDevice != nil {
                            hardwareButtonsSimulatorSection
                        }

                        // MARK: - 3. 4-LED Color Indicators Guide
                        ledSignalsExplanationCard

                        // MARK: - 4. Pair / Device Code Section
                        pairDeviceSection

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }

                // Toast Message
                if let toast = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(toast)
                                .font(Theme.Fonts.bold.swiftUI(size: 13))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.textPrimaryColor.opacity(0.92))
                        .cornerRadius(20)
                        .shadow(radius: 6)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.toastMessage)
                }
            }
            .navigationTitle("Thiết Bị HEROS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text("QUẢN LÝ THIẾT BỊ")
                            .font(Theme.Fonts.bold.swiftUI(size: 16))
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadDeviceData()
            }
            .sheet(isPresented: $showingPairSheet) {
                pairSheet
            }
        }
    }

    // MARK: - Subviews

    private func connectedDeviceCard(_ device: BLEDevice) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                // Device Icon & Hardware LED Light
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.softPink)
                        .frame(width: 60, height: 60)

                    Image(systemName: "shield.checkered")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.Colors.primaryColor)
                        .frame(width: 60, height: 60)

                    // Hardware LED Simulation Dot
                    Circle()
                        .fill(Color(hex: device.ledState.hexColor))
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: Color(hex: device.ledState.hexColor), radius: 4)
                        .offset(x: -3, y: 3)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(Theme.Fonts.bold.swiftUI(size: 16))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text("S/N: \(device.serialNumber) • FW: \(device.firmwareVersion)")
                        .font(Theme.Fonts.regular.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textSecondaryColor)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Đang kết nối")
                                .font(Theme.Fonts.medium.swiftUI(size: 11))
                                .foregroundColor(.green)
                        }

                        Text("•")
                            .foregroundColor(.gray)

                        // Battery Info with Remaining Days
                        Label("Pin \(device.batteryPercentage)% (còn ~\(device.estimatedRemainingDays) ngày)", systemImage: "battery.75")
                            .font(Theme.Fonts.medium.swiftUI(size: 11))
                            .foregroundColor(Theme.Colors.textSecondaryColor)
                    }
                }

                Spacer()
            }

            // Current LED State Banner
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: device.ledState.hexColor))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.ledState.rawValue)
                        .font(Theme.Fonts.bold.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                    Text(device.ledState.instruction)
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                }
                Spacer()
            }
            .padding(10)
            .background(Color(hex: device.ledState.hexColor).opacity(0.1))
            .cornerRadius(10)

            Divider()

            // Siren Test & Disconnect
            HStack {
                Button(action: {
                    viewModel.testSirenAlarm()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isTestingSiren ? "speaker.wave.3.fill" : "speaker.wave.2")
                        Text(viewModel.isTestingSiren ? "Còi đang hú..." : "Thử còi 110dB")
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 12))
                    .foregroundColor(viewModel.isTestingSiren ? .white : Theme.Colors.primaryColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.isTestingSiren ? Theme.Colors.amberColor : Theme.Colors.softPink)
                    .cornerRadius(8)
                }

                Spacer()

                Button(action: {
                    viewModel.disconnectDevice()
                }) {
                    Text("Ngắt kết nối")
                        .font(Theme.Fonts.medium.swiftUI(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var noDeviceCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.primaryColor)

            Text("Chưa Ghép Nối Thiết Bị HEROS")
                .font(Theme.Fonts.bold.swiftUI(size: 16))
                .foregroundColor(Theme.Colors.textPrimaryColor)

            Text("Quy tắc: 1 Thiết bị = 1 Tài khoản = 1 Điện thoại. Quét mã QR hoặc nhập số seri để kích hoạt tính năng cứu hộ phần cứng.")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)
                .multilineTextAlignment(.center)

            Button(action: {
                showingPairSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Quét QR / Nhập Mã Thiết Bị")
                }
                .font(Theme.Fonts.bold.swiftUI(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.Colors.primaryColor)
                .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
    }

    // MARK: - 2-Button Interactive Simulator (Trọng tâm yêu cầu)
    private var hardwareButtonsSimulatorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Mô Phỏng 2 Nút Bấm Vật Lý Trên Thiết Bị")
                    .font(Theme.Fonts.bold.swiftUI(size: 15))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            Text("Chạm và giữ các nút dưới đây để thử nghiệm cơ chế bấm vật lý thật:")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)

            HStack(spacing: 14) {
                // Button 1: SOS Hold 5s
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.redColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 80, height: 80)

                        if viewModel.isHoldingButton1 {
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.button1HoldProgress))
                                .stroke(Theme.Colors.redColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                        }

                        Circle()
                            .fill(Theme.Colors.redColor)
                            .frame(width: 66, height: 66)

                        VStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("SOS")
                                .font(Theme.Fonts.bold.swiftUI(size: 11))
                                .foregroundColor(.white)
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                viewModel.startHoldButton1()
                            }
                            .onEnded { _ in
                                viewModel.cancelHoldButton1()
                            }
                    )

                    Text("NÚT 1: SOS (Giữ 5s)")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text(viewModel.isHoldingButton1 ? "Đang giữ... (\(Int(viewModel.button1HoldProgress * 5))s)" : "Nhấn giữ 5s để phát SOS\nGiữ 5s lại để báo An toàn")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(viewModel.isHoldingButton1 ? Theme.Colors.redColor : Theme.Colors.textSecondaryColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                // Button 2: Audio Recording (Hold to Record, Release to Send)
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.amberColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 80, height: 80)

                        if viewModel.isHoldingButton2 {
                            Circle()
                                .stroke(Theme.Colors.amberColor, lineWidth: 6)
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.1)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isHoldingButton2)
                        }

                        Circle()
                            .fill(Theme.Colors.amberColor)
                            .frame(width: 66, height: 66)

                        VStack(spacing: 2) {
                            Image(systemName: viewModel.isHoldingButton2 ? "waveform" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("THU ÂM")
                                .font(Theme.Fonts.bold.swiftUI(size: 10))
                                .foregroundColor(.white)
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                viewModel.startHoldButton2()
                            }
                            .onEnded { _ in
                                viewModel.releaseHoldButton2()
                            }
                    )

                    Text("NÚT 2: GHI ÂM")
                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text(viewModel.isHoldingButton2 ? "Đang thu: \(viewModel.button2RecordDuration)s\nThả tay để gửi đi!" : "Nhấn giữ để thu âm\nThả tay để tự gửi voice")
                        .font(Theme.Fonts.regular.swiftUI(size: 11))
                        .foregroundColor(viewModel.isHoldingButton2 ? Theme.Colors.amberColor : Theme.Colors.textSecondaryColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    private var ledSignalsExplanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Ý Nghĩa 4 Tín Hiệu Đèn LED & Rung")
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            VStack(spacing: 10) {
                ledRow(
                    colorHex: "#E11D48",
                    title: "Đèn ĐỎ + Rung",
                    detail: "Kích hoạt khi nhấn giữ Nút 1 trong 5s. Đang phát tín hiệu SOS và định vị GPS lên hệ thống."
                )
                Divider()
                ledRow(
                    colorHex: "#10B981",
                    title: "Đèn XANH LÁ + Rung",
                    detail: "Thiết bị nhận được tín hiệu có người trong mạng lưới bấm 'Tôi sẵn sàng ứng cứu' và đang đến."
                )
                Divider()
                ledRow(
                    colorHex: "#F59E0B",
                    title: "Đèn VÀNG",
                    detail: "Sáng trong suốt thời gian bạn nhấn giữ Nút 2 để thu âm cuộc đối thoại làm bằng chứng."
                )
                Divider()
                ledRow(
                    colorHex: "#0284C7",
                    title: "Đèn XANH DƯƠNG",
                    detail: "Sau 5 phút nếu không có ai ứng cứu, hệ thống chuyển sang tự động gọi thoại tới danh sách người thân."
                )
            }
            .padding(12)
            .background(Color(Theme.Colors.bgColor))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    private func ledRow(colorHex: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 12, height: 12)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.bold.swiftUI(size: 13))
                    .foregroundColor(Color(hex: colorHex))
                Text(detail)
                    .font(Theme.Fonts.regular.swiftUI(size: 12))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }
            Spacer()
        }
    }

    private var pairDeviceSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Đổi Hoặc Thêm Thiết Bị")
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
                Text("Quét mã QR hoặc nhập Serial của sản phẩm HEROS")
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }

            Spacer()

            Button(action: {
                showingPairSheet = true
            }) {
                Text("Ghép Nối")
                    .font(Theme.Fonts.bold.swiftUI(size: 12))
                    .foregroundColor(Theme.Colors.primaryColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.softPink)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var pairSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.softPink)
                        .frame(height: 180)

                    VStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text("Quét mã QR trên hộp hoặc mặt lưng thiết bị")
                            .font(Theme.Fonts.regular.swiftUI(size: 12))
                            .foregroundColor(Theme.Colors.textSecondaryColor)
                    }
                }

                Text("HOẶC NHẬP MÃ SERI THỦ CÔNG")
                    .font(Theme.Fonts.bold.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)

                TextField("Ví dụ: HRS-8839-VN", text: $inputSerialNumber)
                    .padding()
                    .background(Color(Theme.Colors.bgColor))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.characters)

                Text("Lưu ý: Mỗi thiết bị chỉ liên kết duy nhất với 1 tài khoản và 1 điện thoại chính chủ.")
                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
                    .multilineTextAlignment(.center)

                Spacer()

                Button(action: {
                    viewModel.pairDevice(code: inputSerialNumber)
                    showingPairSheet = false
                }) {
                    Text("Xác Nhận Ghép Nối")
                        .font(Theme.Fonts.bold.swiftUI(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.primaryColor)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .navigationTitle("Ghép Nối Thiết Bị HEROS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        showingPairSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
