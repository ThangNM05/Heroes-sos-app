//
//  SOSSettingsView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSSettingsView: View {
    @StateObject private var viewModel: SOSSettingsViewModel
    @State private var showingAddContactSheet = false
    @State private var showingPolicySheet = false
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var newContactRelationship = ""

    init(viewModel: SOSSettingsViewModel? = nil) {
        let vm = viewModel ?? SOSSettingsViewModel(sosService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // MARK: - 1. User Role (Bỏ hoàn toàn KYC)
                        userRoleSection

                        // MARK: - 2. Audio & GPS Recipient Target (3 nhóm lựa chọn)
                        recipientTargetSection

                        // MARK: - 3. Priority Trusted Contacts for Auto-Call
                        priorityContactsSection

                        // MARK: - 4. Terms & Policy Disclaimer
                        disclaimerCard

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }

                // Toast
                if viewModel.saveSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Đã lưu thiết lập an toàn!")
                                .font(Theme.Fonts.bold.swiftUI(size: 13))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.primaryColor)
                        .cornerRadius(20)
                        .shadow(radius: 6)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Cài Đặt Cứu Hộ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text("THIẾT LẬP HEROS")
                            .font(Theme.Fonts.bold.swiftUI(size: 16))
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadSettingsAndContacts()
            }
            .sheet(isPresented: $showingAddContactSheet) {
                addContactSheet
            }
            .sheet(isPresented: $showingPolicySheet) {
                policySheet
            }
        }
    }

    // MARK: - Subviews

    // 1. Phân loại tài khoản (Bỏ KYC)
    private var userRoleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.square.filled.and.at.rectangle.fill")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Vai Trò Của Bạn Trong Mạng Lưới HEROS")
                    .font(Theme.Fonts.bold.swiftUI(size: 15))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            Text("Không yêu cầu xác minh CCCD/KYC phức tạp, phân quyền dựa trên nhu cầu sử dụng:")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)

            VStack(spacing: 10) {
                ForEach(HEROSUserRole.allCases) { role in
                    Button(action: {
                        viewModel.updateUserRole(role)
                    }) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(viewModel.settings.userRole == role ? Theme.Colors.primaryColor : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 20, height: 20)

                                if viewModel.settings.userRole == role {
                                    Circle()
                                        .fill(Theme.Colors.primaryColor)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(role.title)
                                        .font(Theme.Fonts.bold.swiftUI(size: 13))
                                        .foregroundColor(Theme.Colors.textPrimaryColor)

                                    if role == .deviceOwner {
                                        Text("Có phím SOS")
                                            .font(Theme.Fonts.semiBold.swiftUI(size: 10))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Theme.Colors.softPink)
                                            .foregroundColor(Theme.Colors.primaryColor)
                                            .cornerRadius(4)
                                    }
                                }

                                Text(role.badgeDescription)
                                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(viewModel.settings.userRole == role ? Theme.Colors.softPink.opacity(0.5) : Color(Theme.Colors.bgColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.settings.userRole == role ? Theme.Colors.primaryColor.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    // 2. Tùy chọn gửi bản ghi âm & Định vị
    private var recipientTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.badge.mic")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Nhóm Nhận Tín Hiệu SOS & Bản Ghi Âm")
                    .font(Theme.Fonts.bold.swiftUI(size: 15))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
            }

            Text("Khi kích hoạt SOS, hệ thống sẽ tự động gửi đồng thời tọa độ GPS và bản ghi âm đối thoại tới:")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)

            VStack(spacing: 8) {
                ForEach(SOSRecipientMode.allCases) { mode in
                    Button(action: {
                        viewModel.updateRecipientMode(mode)
                    }) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(viewModel.settings.recipientMode == mode ? Theme.Colors.primaryColor : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 20, height: 20)

                                if viewModel.settings.recipientMode == mode {
                                    Circle()
                                        .fill(Theme.Colors.primaryColor)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(Theme.Fonts.bold.swiftUI(size: 13))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)

                                Text(mode.description)
                                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(viewModel.settings.recipientMode == mode ? Theme.Colors.softPink.opacity(0.5) : Color(Theme.Colors.bgColor))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    // 3. Danh bạ ưu tiên nhận cuộc gọi tự động
    private var priorityContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill.badge.checkmark")
                        .foregroundColor(Theme.Colors.greenColor)
                    Text("Người Thân Nhận Cuộc Gọi Tự Động")
                        .font(Theme.Fonts.bold.swiftUI(size: 15))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                }

                Spacer()

                Button(action: {
                    showingAddContactSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm")
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 13))
                    .foregroundColor(Theme.Colors.primaryColor)
                }
            }

            Text("Nếu sau 5 phút trong bán kính 5km chưa có ai nhận ứng cứu, hệ thống sẽ tự động gọi thoại lần lượt theo thứ tự ưu tiên (S1 → S2 → S3):")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)

            VStack(spacing: 8) {
                ForEach(viewModel.emergencyContacts) { contact in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primaryColor.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text("S\(contact.priorityOrder)")
                                .font(Theme.Fonts.bold.swiftUI(size: 13))
                                .foregroundColor(Theme.Colors.primaryColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(contact.name)
                                    .font(Theme.Fonts.bold.swiftUI(size: 13))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)
                                Text("(\(contact.relationship))")
                                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                            }
                            Text(contact.phoneNumber)
                                .font(Theme.Fonts.regular.swiftUI(size: 12))
                                .foregroundColor(Theme.Colors.textSecondaryColor)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.deleteContact(id: contact.id)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.6))
                                .padding(6)
                        }
                    }
                    .padding(10)
                    .background(Color(Theme.Colors.bgColor))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    // 4. Disclaimer
    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Theme.Colors.primaryColor)
                Text("Điều Khoản & Trách Nhiệm Của HEROS")
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.textPrimaryColor)
                Spacer()

                Button(action: {
                    showingPolicySheet = true
                }) {
                    Text("Chi tiết")
                        .font(Theme.Fonts.bold.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.primaryColor)
                }
            }

            Text("HEROS là nền tảng công nghệ kết nối tương trợ cộng đồng và không thay thế các dịch vụ cứu hộ khẩn cấp công quyền (113, 114, 115).")
                .font(Theme.Fonts.regular.swiftUI(size: 12))
                .foregroundColor(Theme.Colors.textSecondaryColor)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
    }

    private var addContactSheet: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Họ và tên (VD: Mẹ, Người yêu, Bạn thân...)", text: $newContactName)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                            .cornerRadius(12)

                        TextField("Mối quan hệ (VD: Gia đình, Bạn bè...)", text: $newContactRelationship)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                            .cornerRadius(12)

                        TextField("Số điện thoại di động (VD: 0912 345 678)", text: $newContactPhone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                            .cornerRadius(12)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.addContact(name: newContactName, relationship: newContactRelationship, phone: newContactPhone)
                        newContactName = ""
                        newContactRelationship = ""
                        newContactPhone = ""
                        showingAddContactSheet = false
                    }) {
                        Text("Thêm Vào Danh Sách Ưu Tiên")
                            .font(Theme.Fonts.bold.swiftUI(size: 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.primaryColor)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Thêm Người Thân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        showingAddContactSheet = false
                    }
                    .foregroundColor(Theme.Colors.primaryColor)
                }
            }
        }
        .preferredColorScheme(.light)
        .presentationDetents([.medium])
    }

    private var policySheet: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CHÍNH SÁCH BẢO MẬT & PHẠM VI TRÁCH NHIỆM")
                                .font(Theme.Fonts.extraBold.swiftUI(size: 15))
                                .foregroundColor(Theme.Colors.primaryColor)
                                .tracking(0.5)

                            Text("Quy định vận hành hệ thống trợ giúp khẩn cấp HEROS")
                                .font(Theme.Fonts.regular.swiftUI(size: 12))
                                .foregroundColor(Theme.Colors.textSecondaryColor)
                        }
                        .padding(.bottom, 4)

                        // Card 1: HEROS Trách nhiệm
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Theme.Colors.greenColor)
                                    .font(.system(size: 16))
                                Text("1. HEROS CHỊU TRÁCH NHIỆM GÌ?")
                                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                policyItem(text: "Kịp thời truyền phát tín hiệu SOS, vị trí GPS chính xác cao của người dùng lên bản đồ cứu hộ cộng đồng.")
                                policyItem(text: "Mã hóa an toàn và gửi tệp ghi âm hiện trường đối thoại tới danh bạ người thân do người dùng chỉ định.")
                                policyItem(text: "Tự động kích hoạt cuộc gọi thoại khẩn cấp tới danh sách người thân khi không có phản hồi cứu trợ sau 5 phút.")
                                policyItem(text: "Xử lý nghiêm khắc các trường hợp báo động giả (tạm khóa 30 ngày sau 3 lần kích hoạt sai).")
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                        // Card 2: HEROS Miễn trừ
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                Text("2. HEROS KHÔNG CHỊU TRÁCH NHIỆM GÌ?")
                                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                                    .foregroundColor(Theme.Colors.textPrimaryColor)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                policyItem(text: "HEROS không thay thế lực lượng an ninh công quyền 113 hay cấp cứu y tế 115.")
                                policyItem(text: "Không chịu trách nhiệm trường hợp thiết bị mất sóng viễn thông, tắt GPS hệ điều hành hoặc hết pin điện thoại.")
                                policyItem(text: "Không cam kết chắc chắn về thời gian có mặt thực tế của các tình nguyện viên cộng đồng.")
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Điều Khoản HEROS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đã hiểu") {
                        showingPolicySheet = false
                    }
                    .font(Theme.Fonts.bold.swiftUI(size: 14))
                    .foregroundColor(Theme.Colors.primaryColor)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func policyItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(Theme.Fonts.bold.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.primaryColor)
            Text(text)
                .font(Theme.Fonts.regular.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textPrimaryColor)
                .lineSpacing(3)
        }
    }
}
