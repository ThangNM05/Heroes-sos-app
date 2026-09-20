//
//  SOSEntities.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/31/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - User Role Classification (Không cần KYC)
enum HEROSUserRole: String, Codable, CaseIterable, Identifiable {
    case deviceOwner = "Người sở hữu thiết bị HEROS"
    case trustedContact = "Người thân / Bạn bè được mời"
    case communityHero = "Tình nguyện viên / Người hỗ trợ"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deviceOwner:
            return "Chủ Thiết Bị (Loại 1)"
        case .trustedContact:
            return "Người Thân (Loại 2)"
        case .communityHero:
            return "Hỗ Trợ Cộng Đồng (Loại 3)"
        }
    }

    var badgeDescription: String {
        switch self {
        case .deviceOwner:
            return "1 Thiết bị = 1 Tài khoản = 1 Điện thoại. Có quyền bấm SOS, thu âm và phát tín hiệu cứu hộ."
        case .trustedContact:
            return "Tải app theo lời mời của người thân. Nhận thông báo GPS, file ghi âm và cuộc gọi tự động khi người thân gặp sự cố."
        case .communityHero:
            return "Thành viên sẵn sàng tương trợ khi có người gặp nạn trong bán kính gần. Không có tính năng phát SOS."
        }
    }

    var iconName: String {
        switch self {
        case .deviceOwner:
            return "shield.checkered"
        case .trustedContact:
            return "person.2.fill"
        case .communityHero:
            return "heart.circle.fill"
        }
    }
}

// MARK: - Recipient Target Mode
enum SOSRecipientMode: String, Codable, CaseIterable, Identifiable {
    case all = "Tất cả (Cộng đồng & Người thân)"
    case trustedContactsOnly = "Chỉ gửi Người thân, bạn bè"
    case communityOnly = "Chỉ gửi Mạng lưới hỗ trợ HEROS"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .all:
            return "Cộng đồng & Người thân"
        case .trustedContactsOnly:
            return "Người thân tin cậy"
        case .communityOnly:
            return "Mạng lưới HEROS"
        }
    }

    var description: String {
        switch self {
        case .all:
            return "Gửi đồng thời tọa độ GPS và bản ghi âm đối thoại đến cả người thân và các thành viên xung quanh bạn."
        case .trustedContactsOnly:
            return "Chỉ gửi thông tin đến danh sách người thân/bạn bè được bạn chỉ định ưu tiên."
        case .communityOnly:
            return "Chỉ gửi thông báo tìm kiếm đến các thành viên cộng đồng HEROS gần bạn nhất."
        }
    }

    var iconName: String {
        switch self {
        case .all:
            return "person.3.fill"
        case .trustedContactsOnly:
            return "heart.text.square.fill"
        case .communityOnly:
            return "network"
        }
    }
}

// MARK: - Hardware LED & Vibration States
enum DeviceLEDState: String, Codable {
    case off = "Đèn Tắt (Chờ)"
    case sosActiveRed = "Đèn ĐỎ + Rung (Đang phát SOS)"
    case responderIncomingGreen = "Đèn XANH LÁ + Rung (Đã có người đến cứu)"
    case recordingYellow = "Đèn VÀNG (Đang thu âm)"
    case autoCallBlue = "Đèn XANH DƯƠNG (Tổng đài đang gọi người thân)"

    var hexColor: String {
        switch self {
        case .off: return "#8E8A9F"
        case .sosActiveRed: return "#E11D48"
        case .responderIncomingGreen: return "#10B981"
        case .recordingYellow: return "#F59E0B"
        case .autoCallBlue: return "#0284C7"
        }
    }

    var instruction: String {
        switch self {
        case .off:
            return "Thiết bị ở chế độ an toàn. Nhấn giữ Nút 1 trong 5s để phát SOS."
        case .sosActiveRed:
            return "Đang gửi tọa độ GPS và tìm kiếm người ứng cứu. Nhấn giữ 5s lại để xác nhận an toàn."
        case .responderIncomingGreen:
            return "Đã có người trong mạng lưới xác nhận đang trên đường đến hỗ trợ bạn!"
        case .recordingYellow:
            return "Đang thu âm đối thoại làm chứng cứ. Thả tay để gửi voice note đi."
        case .autoCallBlue:
            return "Hệ thống đang tự động quay số gọi cho danh sách người thân của bạn."
        }
    }
}

// MARK: - Audio Record (Voice Memo Style)
struct AudioRecord: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let durationSeconds: Int
    let recordedAt: Date
    let fileURL: String
    var isEvidence: Bool

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - SOS Alert Entity
struct SOSAlert: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let senderName: String
    let senderPhone: String
    let senderAvatar: String
    let latitude: Double
    let longitude: Double
    var addressName: String
    let createdAt: Date
    var status: SOSStatus
    let recipientMode: SOSRecipientMode
    var audioRecords: [AudioRecord] = []
    var isHardwareTriggered: Bool
    var distanceInMeters: Double?
    var respondersCount: Int = 0
    var currentRadiusMeters: Double = 500
    var isCallFallbackTriggered: Bool = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var timeAgoString: String {
        let elapsed = Int(Date().timeIntervalSince(createdAt))
        if elapsed < 60 {
            return "\(max(1, elapsed)) giây trước"
        } else if elapsed < 3600 {
            return "\(elapsed / 60) phút trước"
        } else {
            return "\(elapsed / 3600) giờ trước"
        }
    }

    enum SOSStatus: String, Codable {
        case active = "Đang tìm kiếm cứu hộ"
        case responding = "Đã có người ứng cứu"
        case resolved = "Đã an toàn"
    }
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var relationship: String
    var phoneNumber: String
    var avatarUrl: String?
    var priorityOrder: Int
    var isTrusted: Bool
    var isNotifiedViaSMS: Bool
    var isNotifiedViaCall: Bool
}

// MARK: - BLE Hardware Device
struct BLEDevice: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var model: String
    var serialNumber: String
    var batteryPercentage: Int
    var estimatedRemainingDays: Int
    var isConnected: Bool
    var sirenDecibels: Int
    var firmwareVersion: String
    var ledState: DeviceLEDState
    var isSirenActive: Bool
    var lastSyncDate: Date
}

// MARK: - SOS User Settings
struct SOSSettings: Codable, Equatable {
    var userRole: HEROSUserRole = .deviceOwner
    var recipientMode: SOSRecipientMode = .all
    var autoRecordAudio: Bool = true
    var autoTriggerSiren: Bool = false
    var sirenVolumeDecibels: Int = 110
    var countdownDurationSeconds: Int = 3
    var shareLiveLocation: Bool = true
    var maxSearchRadiusKm: Double = 5.0
    var stepIntervalSeconds: Int = 30
    var autoCallAfterMinutes: Int = 5
}

// MARK: - False Alarm Report
struct FalseAlarmReport: Identifiable, Codable, Equatable {
    let id: String
    let alertId: String
    let reporterName: String
    let reporterPhone: String
    let reason: ReportReason
    let note: String
    let createdAt: Date

    enum ReportReason: String, Codable, CaseIterable, Identifiable {
        case prank = "Người dùng đùa giỡn / Báo động giả"
        case noOneThere = "Đến nơi nhưng không thấy nạn nhân"
        case accidental = "Bấm nhầm nút thiết bị"
        case other = "Lý do khác"

        var id: String { rawValue }
    }
}

// MARK: - Women's Safety & Health Handbook
struct HandbookArticle: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let category: HandbookCategory
    let summary: String
    let content: String
    let iconName: String
    let readTimeMinutes: Int

    enum HandbookCategory: String, Codable, CaseIterable, Identifiable {
        case dangerousSituations = "Kỹ Năng Thoát Hiểm"
        case selfDefense = "Bí Quyết Tự Vệ"
        case womenHealth = "Dinh Dưỡng & Sức Khỏe"
        case hotlines = "Tổng Đài Trợ Giúp"

        var id: String { rawValue }
    }
}
