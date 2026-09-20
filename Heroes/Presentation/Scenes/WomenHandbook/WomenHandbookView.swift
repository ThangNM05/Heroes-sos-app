//
//  WomenHandbookView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 9/16/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct WomenHandbookView: View {
    @StateObject private var viewModel: WomenHandbookViewModel
    @State private var selectedArticle: HandbookArticle? = nil

    init(viewModel: WomenHandbookViewModel? = nil) {
        let vm = viewModel ?? WomenHandbookViewModel(sosService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Theme.Colors.bgColor).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // MARK: - 1. Hero Header Banner
                        heroBanner

                        // MARK: - 2. Quick Emergency Hotlines
                        emergencyHotlinesRow

                        // MARK: - 3. Category Filter Chips
                        categoryFilterChips

                        // MARK: - 4. Articles List
                        articlesListView

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Cẩm Nang Phái Đẹp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text("CẨM NANG PHÁI ĐẸP")
                            .font(Theme.Fonts.bold.swiftUI(size: 16))
                            .foregroundColor(Theme.Colors.textPrimaryColor)
                    }
                }
            }
            .onAppear {
                viewModel.loadArticles()
            }
            .sheet(item: $selectedArticle) { article in
                articleDetailSheet(article)
            }
        }
    }

    // MARK: - Subviews

    private var heroBanner: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HEROS CARE & SAFETY")
                    .font(Theme.Fonts.bold.swiftUI(size: 11))
                    .foregroundColor(Theme.Colors.primaryColor)
                    .tracking(1)

                Text("Đồng Hành & Bảo Vệ Bạn Mọi Lúc Mọi Nơi")
                    .font(Theme.Fonts.bold.swiftUI(size: 16))
                    .foregroundColor(Theme.Colors.textPrimaryColor)

                Text("Trang bị kỹ năng tự vệ, bí kíp thoát hiểm và kiến thức chăm sóc sức khỏe.")
                    .font(Theme.Fonts.regular.swiftUI(size: 12))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.softPink)
                    .frame(width: 56, height: 56)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.primaryColor)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var emergencyHotlinesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Đường Dây Nóng Khẩn Cấp (Chạm để gọi)")
                .font(Theme.Fonts.bold.swiftUI(size: 13))
                .foregroundColor(Theme.Colors.textPrimaryColor)

            HStack(spacing: 10) {
                hotlinePill(title: "Công An 113", number: "113", color: Theme.Colors.redColor)
                hotlinePill(title: "Cấp Cứu 115", number: "115", color: Theme.Colors.blueColor)
                hotlinePill(title: "Ngôi Nhà Bình Yên", number: "1900969680", color: Theme.Colors.primaryColor)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
    }

    private func hotlinePill(title: String, number: String, color: Color) -> some View {
        Button(action: {
            if let url = URL(string: "tel://\(number)") {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(spacing: 3) {
                Text(title)
                    .font(Theme.Fonts.bold.swiftUI(size: 11))
                    .foregroundColor(color)
                    .lineLimit(1)
                Text(number)
                    .font(Theme.Fonts.regular.swiftUI(size: 10))
                    .foregroundColor(Theme.Colors.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }

    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "Tất cả", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.filterByCategory(nil)
                }

                ForEach(HandbookArticle.HandbookCategory.allCases) { category in
                    categoryChip(title: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                        viewModel.filterByCategory(category)
                    }
                }
            }
        }
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.bold.swiftUI(size: 12))
                .foregroundColor(isSelected ? .white : Theme.Colors.textPrimaryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.Colors.primaryColor : Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    private var articlesListView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.articles) { article in
                Button(action: {
                    selectedArticle = article
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.Colors.softPink)
                                .frame(width: 52, height: 52)
                            Image(systemName: article.iconName)
                                .font(.system(size: 22))
                                .foregroundColor(Theme.Colors.primaryColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.category.rawValue)
                                .font(Theme.Fonts.semiBold.swiftUI(size: 10))
                                .foregroundColor(Theme.Colors.primaryColor)

                            Text(article.title)
                                .font(Theme.Fonts.bold.swiftUI(size: 14))
                                .foregroundColor(Theme.Colors.textPrimaryColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                                Text("\(article.readTimeMinutes) phút đọc")
                                    .font(Theme.Fonts.regular.swiftUI(size: 11))
                                    .foregroundColor(Theme.Colors.textSecondaryColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondaryColor.opacity(0.6))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    private func articleDetailSheet(_ article: HandbookArticle) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: article.iconName)
                            .foregroundColor(Theme.Colors.primaryColor)
                        Text(article.category.rawValue)
                            .font(Theme.Fonts.bold.swiftUI(size: 12))
                            .foregroundColor(Theme.Colors.primaryColor)
                    }

                    Text(article.title)
                        .font(Theme.Fonts.bold.swiftUI(size: 18))
                        .foregroundColor(Theme.Colors.textPrimaryColor)

                    Text(article.summary)
                        .font(Theme.Fonts.medium.swiftUI(size: 13))
                        .foregroundColor(Theme.Colors.textSecondaryColor)
                        .padding(12)
                        .background(Theme.Colors.softPink.opacity(0.5))
                        .cornerRadius(12)

                    Divider()

                    Text("HƯỚNG DẪN CHI TIẾT")
                        .font(Theme.Fonts.bold.swiftUI(size: 12))
                        .foregroundColor(Theme.Colors.textSecondaryColor)

                    Text(article.content)
                        .font(Theme.Fonts.regular.swiftUI(size: 14))
                        .foregroundColor(Theme.Colors.textPrimaryColor)
                        .lineSpacing(6)
                }
                .padding(20)
            }
            .navigationTitle("Chi Tiết Cẩm Nang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng") {
                        selectedArticle = nil
                    }
                }
            }
        }
    }
}
