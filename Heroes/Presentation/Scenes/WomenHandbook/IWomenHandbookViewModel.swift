//
//  IWomenHandbookViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 9/16/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol IWomenHandbookViewModel: AnyObject {
    var articles: [HandbookArticle] { get }
    var selectedCategory: HandbookArticle.HandbookCategory? { get }

    func loadArticles()
    func filterByCategory(_ category: HandbookArticle.HandbookCategory?)
}
