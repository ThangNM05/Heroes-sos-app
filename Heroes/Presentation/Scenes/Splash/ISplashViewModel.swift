//
//  ISplashViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
protocol ISplashViewModel: IBaseViewModel {
    var progress: Double { get }
    var isCompleted: Bool { get }

    func startSplashFlow() async
}
