//
//  SOSChatComposer.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/5/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatComposer: View {
    @Binding var text: String
    let canSend: Bool
    let retryUntil: Date?
    let send: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let coolingDown = (retryUntil ?? .distantPast) > context.date
            VStack(alignment: .trailing, spacing: 5) {
                if coolingDown, let retryUntil {
                    Text("Có thể gửi lại sau \(Int(ceil(retryUntil.timeIntervalSince(context.date)))) giây")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Nhắn cho nhóm hỗ trợ", text: $text, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(10).background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!canSend)
                        .onChange(of: text) { _, value in text = SOSChatText.limited(value) }
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                    }
                    .accessibilityLabel("Gửi tin nhắn")
                    .disabled(!canSend || coolingDown || SOSChatText.normalized(text).isEmpty)
                }
                Text("\(text.utf16.count)/\(SOSChatText.maximumLength)").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal).padding(.vertical, 8)
        .background(.bar)
    }
}

