//
//  Inject.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Inject<Value> {
    private(set) public var wrappedValue: Value

    public init() {
        self.wrappedValue = AppDIContainer.shared.resolve()
    }
}
