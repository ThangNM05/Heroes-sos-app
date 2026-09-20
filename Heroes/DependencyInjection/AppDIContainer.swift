//
//  AppDIContainer.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class AppDIContainer: @unchecked Sendable {
    static let shared = AppDIContainer()

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var singletonFactories: [String: () -> Any] = [:]
    private let lock = NSRecursiveLock()

    private init() {}

    func register<T>(_ type: T.Type, isSingleton: Bool = false, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        if isSingleton {
            singletonFactories[key] = factory
        } else {
            factories[key] = factory
        }
    }

    func resolve<T>() -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: T.self)

        if let singleton = singletons[key] as? T {
            return singleton
        }

        if let singletonFactory = singletonFactories[key] {
            guard let instance = singletonFactory() as? T else {
                fatalError("Failed to resolve singleton for \(String(describing: T.self))")
            }
            singletons[key] = instance
            return instance
        }

        if let factory = factories[key], let instance = factory() as? T {
            return instance
        }

        fatalError("Failed to resolve \(String(describing: T.self)). Ensure it is registered in AppDIContainer.")
    }
}
