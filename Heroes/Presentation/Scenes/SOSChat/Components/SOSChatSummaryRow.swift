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

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(urlString: chat.ownerAvatarUrl, initials: String(chat.ownerName.prefix(1)), size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(chat.title).font(.headline)
                Text("\(chat.memberCount) thành viên • \(chat.status == .active ? "Đang hỗ trợ" : "Đã kết thúc")")
                    .font(.caption).foregroundStyle(.secondary)
                Text(chat.createdAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4)
    }
}

