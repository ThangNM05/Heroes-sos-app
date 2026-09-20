//
//  SplashView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel

    init(viewModel: SplashViewModel? = nil) {
        let vm = viewModel ?? SplashViewModel(splashService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        Group {
            if viewModel.isCompleted {
                MainTabView()
            } else {
                ZStack {
                    Color(Theme.Colors.bgColor).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Spacer()

                        // App Logo & Branding (HEROS Brand Identity)
                        VStack(spacing: 14) {
                            Image("img_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .shadow(color: Theme.Colors.primaryColor.opacity(0.15), radius: 12, x: 0, y: 6)

                            VStack(spacing: 4) {
                                Text("HEROS")
                                    .font(Theme.Fonts.extraBold.swiftUI(size: 32))
                                    .foregroundColor(Theme.Colors.primaryColor)
                                    .tracking(3)

                                HStack(spacing: 6) {
                                    Rectangle()
                                        .fill(Theme.Colors.primaryColor.opacity(0.4))
                                        .frame(width: 20, height: 1)
                                    
                                    Text("SAFETY WITH YOU")
                                        .font(Theme.Fonts.bold.swiftUI(size: 11))
                                        .foregroundColor(Theme.Colors.textSecondaryColor)
                                        .tracking(2)

                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.Colors.primaryColor)

                                    Rectangle()
                                        .fill(Theme.Colors.primaryColor.opacity(0.4))
                                        .frame(width: 20, height: 1)
                                }
                            }
                        }

                        Spacer()

                        // Progress Bar & Loading Status
                        VStack(spacing: 12) {
                            ProgressView(value: viewModel.progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.primaryColor))
                                .frame(width: 220)
                                .animation(.easeInOut(duration: 0.2), value: viewModel.progress)

                            Text("Đang kết nối mạng lưới cứu hộ...")
                                .font(Theme.Fonts.regular.swiftUI(size: 12))
                                .foregroundColor(Theme.Colors.textSecondaryColor)
                        }

                        Text("Phiên bản \(Constants.AppInfo.AppVersion)")
                            .font(Theme.Fonts.regular.swiftUI(size: 11))
                            .foregroundColor(Theme.Colors.textSecondaryColor)
                            .padding(.bottom, 24)
                    }
                    .padding()
                }
                .task {
                    await viewModel.startSplashFlow()
                }
            }
        }
    }
}

#Preview {
    SplashView(
        viewModel: SplashViewModel(
            splashService: SplashService(
                repository: SplashRepository()
            )
        )
    )
}
