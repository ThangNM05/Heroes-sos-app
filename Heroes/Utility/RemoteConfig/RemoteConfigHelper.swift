//
//  RemoteConfigHelper.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

class RemoteConfigHelper {
    static let shared = RemoteConfigHelper()

    private var remoteConfigFetched = false

    private init() {}

    func fetchConfig(_ onCompleted: (() -> Void)?) {
        if remoteConfigFetched {
            onCompleted?()
            return
        }
        remoteConfigFetched = true

        FirebaseEnvironment.shared.fetchConfig {
            onCompleted?()
        }
    }

    func getStringValue(fromKey key: RemoteConfigKey) -> String {
        return FirebaseEnvironment.shared.getStringValue(fromKey: key)
    }

    func getNumberValue(fromKey key: RemoteConfigKey) -> NSNumber {
        let str = getStringValue(fromKey: key)
        if let num = Double(str) {
            return NSNumber(value: num)
        }
        return 0
    }

    func getBooleanValue(fromKey key: RemoteConfigKey) -> Bool {
        return FirebaseEnvironment.shared.getBooleanValue(fromKey: key)
    }
}
