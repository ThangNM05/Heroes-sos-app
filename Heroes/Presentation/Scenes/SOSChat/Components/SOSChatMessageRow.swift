//
//  SOSChatMessageRow.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatMessageRow: View {
    let message: SOSChatMessage
    let isOwn: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOwn { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 5) {
                if !isOwn {
                    Text(message.sender.name).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                }
                Text(verbatim: message.text)
                    .font(.body)
                Text(message.createdAt, style: .time).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(isOwn ? Theme.Colors.primaryColor.opacity(0.12) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            if !isOwn { Spacer(minLength: 40) }
        }
    }
}

struct SOSChatPendingRow: View {
    let message: SOSChatPendingMessage
    let retry: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 6) {
                Text(verbatim: message.text).padding(12)
                    .background(Theme.Colors.primaryColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                switch message.state {
                case .sending:
                    Label("Đang gửi", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                case .failed:
                    Button("Gửi lại", action: retry).font(.caption)
                case .blocked:
                    Text("Không thể gửi tin này").font(.caption).foregroundStyle(.red)
                }
            }
        }
    }
}

