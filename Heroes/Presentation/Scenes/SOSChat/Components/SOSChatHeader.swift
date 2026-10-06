//
//  SOSChatHeader.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/6/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SOSChatHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppBackButton(action: close)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).lineLimit(1)
                if title != "Nhóm hỗ trợ SOS" {
                    Text("Nhóm hỗ trợ SOS").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundStyle(Theme.Colors.primaryColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.Colors.softPink)
    }
}
