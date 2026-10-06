//
//  SOSChatSummaryRow.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatSummaryRow: View {
    let chat: SOSChatSummary
    var hasMessages: Bool?

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(urlString: chat.ownerAvatarUrl, initials: String(chat.ownerName.prefix(1)), size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(chat.title).font(.headline)
                Text("\(chat.memberCount) thành viên • \(chat.status == .active ? "Đang hỗ trợ" : "Đã kết thúc")")
                    .font(.caption).foregroundStyle(.secondary)
                Text(chat.createdAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption2).foregroundStyle(.secondary)
                if chat.status == .closed {
                    Label(hasMessages.map { $0 ? "Có tin nhắn còn lưu" : "Không có tin nhắn còn lưu" } ?? "Chưa xác định lịch sử tin nhắn",
                          systemImage: hasMessages == true ? "bubble.left.and.bubble.right.fill" : "bubble.left")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(hasMessages == true ? Theme.Colors.primaryColor : Color.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.Colors.softPink, in: Capsule())
                }
            }
        }.padding(.vertical, 4)
    }
}
