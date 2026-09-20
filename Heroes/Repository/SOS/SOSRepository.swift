//
//  SOSRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class SOSRepository: ISOSRepository {
    private var currentSettings: SOSSettings = SOSSettings(
        userRole: .deviceOwner,
        recipientMode: .all,
        autoRecordAudio: true,
        autoTriggerSiren: false,
        sirenVolumeDecibels: 110,
        countdownDurationSeconds: 3,
        shareLiveLocation: true,
        maxSearchRadiusKm: 5.0,
        stepIntervalSeconds: 30,
        autoCallAfterMinutes: 5
    )

    private var activeSOS: SOSAlert? = nil

    private var mockCommunityAlerts: [SOSAlert] = [
        SOSAlert(
            id: "SOS-HEROS-8091",
            senderId: "user_102",
            senderName: "Lê Minh Thư",
            senderPhone: "0912 345 678",
            senderAvatar: "person.crop.circle.fill",
            latitude: 21.028511,
            longitude: 105.854444,
            addressName: "Số 124 Phố Huế, P. Ngô Thì Nhậm, Q. Hai Bà Trưng, Hà Nội",
            createdAt: Date().addingTimeInterval(-180), // 3 mins ago
            status: .responding,
            recipientMode: .all,
            audioRecords: [
                AudioRecord(
                    id: "REC-901A",
                    title: "Voice Memo #1 (Tiếng tranh cãi)",
                    durationSeconds: 15,
                    recordedAt: Date().addingTimeInterval(-180),
                    fileURL: "https://mock.storage/audio/sos-901a.m4a",
                    isEvidence: true
                ),
                AudioRecord(
                    id: "REC-901B",
                    title: "Voice Memo #2 (Kẻ xấu bám theo)",
                    durationSeconds: 24,
                    recordedAt: Date().addingTimeInterval(-120),
                    fileURL: "https://mock.storage/audio/sos-901b.m4a",
                    isEvidence: true
                )
            ],
            isHardwareTriggered: true,
            distanceInMeters: 450,
            respondersCount: 2,
            currentRadiusMeters: 1000,
            isCallFallbackTriggered: false
        ),
        SOSAlert(
            id: "SOS-HEROS-7723",
            senderId: "user_103",
            senderName: "Hoàng Ngọc Ánh",
            senderPhone: "0988 765 432",
            senderAvatar: "person.crop.circle.fill.badge.checkmark",
            latitude: 21.033333,
            longitude: 105.843333,
            addressName: "Ngõ 45 Trần Phú, P. Điện Biên, Q. Ba Đình, Hà Nội",
            createdAt: Date().addingTimeInterval(-50), // 50s ago
            status: .active,
            recipientMode: .all,
            audioRecords: [
                AudioRecord(
                    id: "REC-902",
                    title: "Voice Memo hiện trường (Cần người giúp ngay)",
                    durationSeconds: 18,
                    recordedAt: Date().addingTimeInterval(-50),
                    fileURL: "https://mock.storage/audio/sos-902.m4a",
                    isEvidence: true
                )
            ],
            isHardwareTriggered: true,
            distanceInMeters: 850,
            respondersCount: 0,
            currentRadiusMeters: 500,
            isCallFallbackTriggered: false
        ),
        SOSAlert(
            id: "SOS-HEROS-6510",
            senderId: "user_104",
            senderName: "Trần Mai Phương (Bạn thân)",
            senderPhone: "0904 112 233",
            senderAvatar: "person.crop.circle.badge.exclamationmark.fill",
            latitude: 21.018900,
            longitude: 105.829900,
            addressName: "Số 226 Thái Hà, P. Trung Liệt, Q. Đống Đa, Hà Nội",
            createdAt: Date().addingTimeInterval(-2400),
            status: .resolved,
            recipientMode: .trustedContactsOnly,
            audioRecords: [
                AudioRecord(
                    id: "REC-903",
                    title: "Voice Memo va chạm xe",
                    durationSeconds: 35,
                    recordedAt: Date().addingTimeInterval(-2400),
                    fileURL: "https://mock.storage/audio/sos-903.m4a",
                    isEvidence: true
                )
            ],
            isHardwareTriggered: false,
            distanceInMeters: 2800,
            respondersCount: 3,
            currentRadiusMeters: 3000,
            isCallFallbackTriggered: false
        )
    ]

    private var mockEmergencyContacts: [EmergencyContact] = [
        EmergencyContact(
            id: "EC-1",
            name: "Mẹ (Nguyễn Thị Lan)",
            relationship: "Gia đình",
            phoneNumber: "0912 888 999",
            avatarUrl: nil,
            priorityOrder: 1,
            isTrusted: true,
            isNotifiedViaSMS: true,
            isNotifiedViaCall: true
        ),
        EmergencyContact(
            id: "EC-2",
            name: "Anh Nam (Người yêu)",
            relationship: "Người yêu",
            phoneNumber: "0913 777 666",
            avatarUrl: nil,
            priorityOrder: 2,
            isTrusted: true,
            isNotifiedViaSMS: true,
            isNotifiedViaCall: true
        ),
        EmergencyContact(
            id: "EC-3",
            name: "Huyền Trang (Bạn thân)",
            relationship: "Bạn bè",
            phoneNumber: "0982 123 456",
            avatarUrl: nil,
            priorityOrder: 3,
            isTrusted: true,
            isNotifiedViaSMS: true,
            isNotifiedViaCall: false
        )
    ]

    private var mockFalseAlarmReports: [FalseAlarmReport] = []

    private var mockHandbookArticles: [HandbookArticle] = [
        HandbookArticle(
            id: "HB-01",
            title: "Quy tắc 5 giây thoát hiểm khi bị bám đuôi vào ban đêm",
            category: .dangerousSituations,
            summary: "Cách giữ bình tĩnh, đổi hướng di chuyển vào nơi đông người và kích hoạt chế độ thu âm bí mật HEROS.",
            content: "1. Tuyệt đối không hoảng loạn chạy thẳng vào hẻm vắng.\n2. Lập tức đổi hướng sang cửa hàng tiện lợi hoặc nơi có ánh sáng camera.\n3. Rút điện thoại hoặc nhấn giữ nút ghi âm Nút 2 trên thiết bị HEROS để lưu bằng chứng đối thoại.\n4. Kích hoạt SOS (nhấn giữ 5s) nếu đối tượng tiếp cận trong cự ly nguy hiểm dưới 3 mét.",
            iconName: "figure.walk",
            readTimeMinutes: 3
        ),
        HandbookArticle(
            id: "HB-02",
            title: "3 Đòn tự vệ cơ bản phái nữ dễ áp dụng nhất",
            category: .selfDefense,
            summary: "Sử dụng lòng bàn tay đẩy cằm, đá hạ bộ và dùng đồ dùng cá nhân (chìa khóa, bút) để tẩu thoát.",
            content: "1. Đẩy cằm: Dùng lòng bàn tay dồn lực đẩy mạnh vào cằm kẻ xấu hướng lên trên.\n2. Tấn công điểm yếu: Đá mạnh vào hạ bộ hoặc giẫm gót giày vào mu bàn chân.\n3. Tận dụng vật dụng: Kẹp chìa khóa giữa các ngón tay để tự vệ khi bị ôm từ phía sau.\n4. Mục tiêu là tạo cơ hội thoát thân 3-5 giây để chạy đến chỗ an toàn, không nán lại đôi co.",
            iconName: "hand.raised.fill",
            readTimeMinutes: 4
        ),
        HandbookArticle(
            id: "HB-03",
            title: "Nhóm thực phẩm vàng giúp cân bằng nội tiết tố & giảm căng thẳng",
            category: .womenHealth,
            summary: "Bổ sung Omega-3, hạt lanh, bơ và trà hoa cúc giúp cải thiện giấc ngủ và tinh thần sảng khoái.",
            content: "1. Axit béo Omega-3: Có nhiều trong cá hồi, quả óc chó giúp giảm lo âu và cải thiện tâm trạng.\n2. Rau xanh lá đậm: Rau bina, cải xoăn chứa folate và magie giúp hệ thần kinh thư giãn.\n3. Quả bơ & hạt chia: Nguồn chất béo lành mạnh giúp cân bằng estrogen tự nhiên.\n4. Trà hoa cúc / Trà tâm sen: Thức uống tuyệt vời trước khi ngủ giúp tái tạo năng lượng sau một ngày làm việc.",
            iconName: "leaf.circle.fill",
            readTimeMinutes: 5
        ),
        HandbookArticle(
            id: "HB-04",
            title: "Đường dây nóng hỗ trợ khẩn cấp dành cho phụ nữ",
            category: .hotlines,
            summary: "Danh bạ các tổ chức công quyền, trung tâm hỗ trợ bạo lực gia đình và cứu hộ khẩn cấp tại Việt Nam.",
            content: "• Công An Khẩn Cấp: 113\n• Cấp Cứu Y Tế: 115\n• Tổng đài Quốc gia Bảo vệ Trẻ em & Phụ nữ: 111\n• Đường dây nóng Ngôi Nhà Bình Yên (Hội LHPN Việt Nam): 1900 969 680\n• Đội Hỗ trợ Cứu hộ SOS Hà Nội & TP.HCM: Kết nối nhanh qua mạng lưới HEROS",
            iconName: "phone.bubble.left.fill",
            readTimeMinutes: 2
        )
    ]

    init() {}

    func getSOSSettings() -> SOSSettings {
        return currentSettings
    }

    func updateSOSSettings(_ settings: SOSSettings) {
        self.currentSettings = settings
    }

    func triggerSOS(latitude: Double, longitude: Double, address: String, initialAudio: AudioRecord?, isHardwareTriggered: Bool) async throws -> SOSAlert {
        try? await Task.sleep(nanoseconds: 500_000_000)

        var audios: [AudioRecord] = []
        if let audio = initialAudio {
            audios.append(audio)
        }

        let newAlert = SOSAlert(
            id: "SOS-HEROS-\(Int.random(in: 1000...9999))",
            senderId: "current_user",
            senderName: "Bạn (Cầu cứu khẩn cấp)",
            senderPhone: "0900 000 000",
            senderAvatar: "person.crop.circle.badge.exclamationmark.fill",
            latitude: latitude,
            longitude: longitude,
            addressName: address.isEmpty ? "Vị trí hiện tại của bạn (Định vị GPS HEROS)" : address,
            createdAt: Date(),
            status: .active,
            recipientMode: currentSettings.recipientMode,
            audioRecords: audios,
            isHardwareTriggered: isHardwareTriggered,
            distanceInMeters: 0,
            respondersCount: 0,
            currentRadiusMeters: 500,
            isCallFallbackTriggered: false
        )

        self.activeSOS = newAlert
        self.mockCommunityAlerts.insert(newAlert, at: 0)
        return newAlert
    }

    func resolveActiveSOS(id: String) async throws {
        try? await Task.sleep(nanoseconds: 400_000_000)
        if let index = mockCommunityAlerts.firstIndex(where: { $0.id == id }) {
            mockCommunityAlerts[index].status = .resolved
        }
        if activeSOS?.id == id {
            activeSOS = nil
        }
    }

    func getActiveSOSAlert() -> SOSAlert? {
        return activeSOS
    }

    func getCommunitySOSAlerts() async throws -> [SOSAlert] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return mockCommunityAlerts
    }

    func respondToSOS(alertId: String, isAccepting: Bool) async throws -> SOSAlert {
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard let index = mockCommunityAlerts.firstIndex(where: { $0.id == alertId }) else {
            throw NSError(domain: "SOSRepo", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy sự cố"])
        }

        if isAccepting {
            mockCommunityAlerts[index].respondersCount += 1
            mockCommunityAlerts[index].status = .responding
        }

        return mockCommunityAlerts[index]
    }

    func appendVoiceMemo(alertId: String, record: AudioRecord) async throws {
        if let index = mockCommunityAlerts.firstIndex(where: { $0.id == alertId }) {
            mockCommunityAlerts[index].audioRecords.append(record)
        }
        if activeSOS?.id == alertId {
            activeSOS?.audioRecords.append(record)
        }
    }

    func submitFalseAlarmReport(_ report: FalseAlarmReport) async throws {
        try? await Task.sleep(nanoseconds: 400_000_000)
        mockFalseAlarmReports.append(report)
    }

    func getEmergencyContacts() async throws -> [EmergencyContact] {
        return mockEmergencyContacts.sorted(by: { $0.priorityOrder < $1.priorityOrder })
    }

    func addEmergencyContact(_ contact: EmergencyContact) async throws {
        mockEmergencyContacts.append(contact)
    }

    func deleteEmergencyContact(id: String) async throws {
        mockEmergencyContacts.removeAll(where: { $0.id == id })
    }

    func toggleTrustedContact(id: String) async throws {
        if let index = mockEmergencyContacts.firstIndex(where: { $0.id == id }) {
            mockEmergencyContacts[index].isTrusted.toggle()
        }
    }

    func getHandbookArticles() async throws -> [HandbookArticle] {
        return mockHandbookArticles
    }
}
