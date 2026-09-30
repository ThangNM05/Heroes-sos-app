import SwiftUI

struct DeviceManagementView: View {
    @StateObject private var viewModel: DeviceManagementViewModel
    @State private var showingPairSheet = false
    @State private var serial = "HEROS-DEMO-001"

    init(viewModel: DeviceManagementViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? DeviceManagementViewModel(deviceService: AppDIContainer.shared.resolve(), sosService: AppDIContainer.shared.resolve()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        if let device = viewModel.connectedDevice {
                            deviceSummary(device)
                            quickActions
                        } else {
                            emptyDevice
                        }
                        ledGuide
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Thiết bị HEROS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadDeviceData() }
            .sheet(isPresented: $showingPairSheet) { pairingSheet }
        }
    }

    private func deviceSummary(_ device: BLEDevice) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .font(.system(size: 22)).foregroundColor(Theme.Colors.primaryColor)
                    .frame(width: 48, height: 48).background(Theme.Colors.softPink).clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name).font(Theme.Fonts.bold.swiftUI(size: 16))
                    Label(device.isConnected ? "Đã kết nối" : "Mất kết nối", systemImage: "circle.fill")
                        .font(Theme.Fonts.medium.swiftUI(size: 11))
                        .foregroundColor(device.isConnected ? Theme.Colors.greenColor : Theme.Colors.redColor)
                }
                Spacer()
                Text("\(device.batteryPercentage)%").font(Theme.Fonts.extraBold.swiftUI(size: 20)).foregroundColor(Theme.Colors.greenColor)
            }

            Divider()

            HStack {
                metric("Pin dự kiến", "Còn khoảng \(device.estimatedRemainingDays) ngày", "battery.75")
                Divider().frame(height: 36)
                metric("Lần đồng bộ", device.lastSyncDate.formatted(date: .omitted, time: .shortened), "arrow.triangle.2.circlepath")
                Divider().frame(height: 36)
                metric("Firmware", device.firmwareVersion, "memorychip")
            }
        }
        .padding(18).background(Color.white).cornerRadius(18)
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(Theme.Colors.primaryColor)
            Text(title).font(Theme.Fonts.regular.swiftUI(size: 9)).foregroundColor(Theme.Colors.textSecondaryColor)
            Text(value).font(Theme.Fonts.semiBold.swiftUI(size: 10)).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button { viewModel.testSirenAlarm() } label: {
                Label(viewModel.isTestingSiren ? "Đang thử còi" : "Thử còi", systemImage: "speaker.wave.3.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DeviceActionStyle(primary: true))

            Button { viewModel.disconnectDevice() } label: {
                Label("Ngắt kết nối", systemImage: "link.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DeviceActionStyle(primary: false))
        }
    }

    private var emptyDevice: some View {
        VStack(spacing: 12) {
            Image(systemName: "sensor.tag.radiowaves.forward").font(.system(size: 38)).foregroundColor(Theme.Colors.primaryColor)
            Text("Chưa kết nối thiết bị").font(Theme.Fonts.bold.swiftUI(size: 16))
            Text("Quét QR hoặc nhập serial để liên kết thiết bị HEROS với tài khoản này.")
                .font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor).multilineTextAlignment(.center)
            Button("Kết nối thiết bị") { showingPairSheet = true }
                .font(Theme.Fonts.bold.swiftUI(size: 14)).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 12).background(Theme.Colors.primaryColor).cornerRadius(12)
        }
        .frame(maxWidth: .infinity).padding(24).background(Color.white).cornerRadius(18)
    }

    private var ledGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tín hiệu đèn").font(Theme.Fonts.bold.swiftUI(size: 15))
            ledRow(.sosActiveRed, title: "Đỏ", detail: "Đang gửi tín hiệu SOS")
            ledRow(.responderIncomingGreen, title: "Xanh lá", detail: "Đã có người xác nhận hỗ trợ")
            ledRow(.recordingYellow, title: "Vàng", detail: "Đang ghi âm")
            ledRow(.autoCallBlue, title: "Xanh dương", detail: "Đang liên hệ người thân")
        }
        .padding(18).background(Color.white).cornerRadius(18)
    }

    private func ledRow(_ state: DeviceLEDState, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: state.hexColor)).frame(width: 12, height: 12)
            Text(title).font(Theme.Fonts.bold.swiftUI(size: 13)).frame(width: 80, alignment: .leading)
            Text(detail).font(Theme.Fonts.regular.swiftUI(size: 12)).foregroundColor(Theme.Colors.textSecondaryColor)
            Spacer()
        }
    }

    private var pairingSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "qrcode.viewfinder").font(.system(size: 54)).foregroundColor(Theme.Colors.primaryColor)
                TextField("Serial thiết bị", text: $serial)
                    .textInputAutocapitalization(.characters).padding(14).background(Color(Theme.Colors.bgColor)).cornerRadius(12)
                Button("Liên kết thiết bị") {
                    viewModel.pairDevice(code: serial)
                    showingPairSheet = false
                }
                .font(Theme.Fonts.bold.swiftUI(size: 14)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 14).background(Theme.Colors.primaryColor).cornerRadius(12)
                Spacer()
            }
            .padding(20).navigationTitle("Kết nối thiết bị").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Hủy") { showingPairSheet = false } } }
        }
        .presentationDetents([.medium])
    }
}

private struct DeviceActionStyle: ButtonStyle {
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.semiBold.swiftUI(size: 12))
            .foregroundColor(primary ? .white : Theme.Colors.primaryColor)
            .padding(.vertical, 12)
            .background(primary ? Theme.Colors.primaryColor : Theme.Colors.softPink)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
