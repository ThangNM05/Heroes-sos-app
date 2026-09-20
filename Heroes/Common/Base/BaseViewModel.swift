//
//  BaseViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
class BaseViewModel: IBaseViewModel {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init() {}

    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
    }

    func clearError() {
        self.errorMessage = nil
    }
}
