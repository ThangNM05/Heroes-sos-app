//
//  AbstractEnvironment.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol AbstractEnvironment {
    func getStringValue(fromKey key: RemoteConfigKey) -> String
    func getBooleanValue(fromKey key: RemoteConfigKey) -> Bool
    func getNumberValue(fromKey key: RemoteConfigKey) -> NSNumber
}
