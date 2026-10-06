//
//  AppLoadingView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 10/6/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct AppLoadingPreferenceKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Transparent blocking scrim. Removing it also disposes the animation state.
struct AppLoadingView: View {
    var message = "Đang xử lý…"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.20).ignoresSafeArea()
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.84)
                    .stroke(
                        AngularGradient(colors: [Theme.Colors.primaryColor.opacity(0.25),
                                                 Theme.Colors.primaryColor,
                                                 Theme.Colors.primaryDarkColor,
                                                 Color.purple],
                                        center: .center, startAngle: .degrees(0), endAngle: .degrees(302.4)),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 1.1).repeatForever(autoreverses: false), value: animate)
                Image("img_logo")
                    .resizable().scaledToFit()
                    .frame(width: 56, height: 56)
            }
            .frame(width: 128, height: 128)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            }
            .shadow(color: .black.opacity(0.16), radius: 24, y: 10)
        }
        .contentShape(Rectangle())
        .onAppear { animate = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
