//
//  WomenHandbookViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 9/16/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class WomenHandbookViewModel: BaseViewModel, IWomenHandbookViewModel {
    @Published var articles: [HandbookArticle] = []
    @Published var allArticles: [HandbookArticle] = []
    @Published var selectedCategory: HandbookArticle.HandbookCategory? = nil

    private let sosService: ISOSService

    init(sosService: ISOSService) {
        self.sosService = sosService
        super.init()
    }

    func loadArticles() {
        isLoading = true
        Task {
            do {
                let fetched = try await sosService.fetchHandbookArticles()
                self.allArticles = fetched
                self.filterByCategory(self.selectedCategory)
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }

    func filterByCategory(_ category: HandbookArticle.HandbookCategory?) {
        self.selectedCategory = category
        if let cat = category {
            self.articles = allArticles.filter { $0.category == cat }
        } else {
            self.articles = allArticles
        }
    }
}
