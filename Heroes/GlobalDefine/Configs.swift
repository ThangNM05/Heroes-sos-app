//
//  Configs.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import UIKit

enum Configs {
    
    // MARK: - Info App
    enum InfoApp {
        static var appId: String { AppConfigs.shared.applicationID() }
        static var appsFlyerId: String { AppConfigs.shared.appsFlyerID() }
        static var email: String { AppConfigs.shared.emailDeveloper() }
        static var appGroup: String { AppConfigs.shared.appGroupID() }
        static var policyUrl: String { AppConfigs.shared.privacyPolicyUrl() }
        static var termOfUseUrl: String { AppConfigs.shared.termOfUseUrl() }
        static var refundUrl: String { AppConfigs.shared.refundUrl() }
        static var enableShowUpdateAppDialog: Bool { AppConfigs.shared.enableShowUpdateAppDialog() }
    }
    
    // MARK: - Server
    enum Server {
        static var baseURL: String { AppConfigs.shared.baseURL() }
        static var searchAdsTrackingBaseURL: String { AppConfigs.shared.searchAdsTrackingBaseURL() }
    }
    
    // MARK: - Network
    enum Network {
        static var baseURL: String { AppConfigs.shared.baseURL() }
        static let perPage = 10
        static let networkTimeout: TimeInterval = 30 // seconds
    }
    
    // MARK: - InAppPurchase
    enum InAppPurchase {
        static var enableShowInApp: Bool { AppConfigs.shared.enableShowInApp() }
        static var enableShowInAppWhenOpenApp: Bool { AppConfigs.shared.enableShowInAppWhenOpenApp() }
        static var limitedFeature: Bool { AppConfigs.shared.limitedFeature() }
        static var iAPSubcriptionSecret: String { AppConfigs.shared.iAPSubcriptionSecret() }
        static var oneTime: String { AppConfigs.shared.iapOneTime() }
        static var weekly: String { AppConfigs.shared.iAPIWeekly() }
        static var monthly: String { AppConfigs.shared.iAPMonthly() }
        static var yearly: String { AppConfigs.shared.iAPYearly() }
    }
    
    // MARK: - LocalNotification
    enum LocalNotification {
        static var enableLocalNotification: Bool { AppConfigs.shared.enableLocalNotification() }
        static var timeTriggerNoti: TimeInterval { AppConfigs.shared.timeTriggerNotification() }
    }
}

// MARK: - AppConfigs Helper (reads directly from AppDebug/AppRelease xcconfig values via Bundle.main)
fileprivate class AppConfigs {
    fileprivate static let shared = AppConfigs()
    
    private init() {}
    
    private func infoValue<T>(forKey key: String, fallback: T) -> T {
        if let appConfigs = Bundle.main.object(forInfoDictionaryKey: "AppConfigs") as? [String: Any],
           let val = appConfigs[key] as? T {
            return val
        }
        if let val = Bundle.main.object(forInfoDictionaryKey: key) as? T {
            return val
        }
        return fallback
    }
    
    private func boolValue(forKey key: String, fallback: Bool) -> Bool {
        let strVal: String = infoValue(forKey: key, fallback: "")
        if !strVal.isEmpty {
            let lower = strVal.lowercased()
            if lower == "yes" || lower == "true" || lower == "1" {
                return true
            } else if lower == "no" || lower == "false" || lower == "0" {
                return false
            }
        }
        return infoValue(forKey: key, fallback: fallback)
    }
    
    // MARK: Info App
    func applicationID() -> String { infoValue(forKey: "ApplicationID", fallback: "id1498001784") }
    func appsFlyerID() -> String { infoValue(forKey: "AppsFlyerID", fallback: "123") }
    func emailDeveloper() -> String { infoValue(forKey: "EmailDeveloper", fallback: "developer@example.com") }
    func appGroupID() -> String { infoValue(forKey: "AppGroupID", fallback: "group.com.test.app.new.app") }
    func privacyPolicyUrl() -> String { infoValue(forKey: "PrivacyPolicyUrl", fallback: "https://example.com/privacy") }
    func termOfUseUrl() -> String { infoValue(forKey: "TermOfUseUrl", fallback: "https://example.com/terms") }
    func refundUrl() -> String { infoValue(forKey: "RefundUrl", fallback: "https://example.com/refund") }
    func enableShowUpdateAppDialog() -> Bool { boolValue(forKey: "EnableShowUpdateAppDialog", fallback: true) }
    
    // MARK: Server
    func baseURL() -> String { infoValue(forKey: "BaseURL", fallback: "https://api.example.com/") }
    func searchAdsTrackingBaseURL() -> String { infoValue(forKey: "SearchAdsTrackingBaseURL", fallback: "https://appletracking.addonsmaster.com/") }
    
    // MARK: InAppPurchase
    func enableShowInApp() -> Bool { boolValue(forKey: "EnableShowInApp", fallback: true) }
    func enableShowInAppWhenOpenApp() -> Bool { boolValue(forKey: "EnableShowInAppWhenOpenApp", fallback: true) }
    func limitedFeature() -> Bool { boolValue(forKey: "LimitedFeature", fallback: true) }
    func iAPSubcriptionSecret() -> String { infoValue(forKey: "IAPSubcriptionSecret", fallback: "d709f7978cbf4c33b74c899b53222a66") }
    func iapOneTime() -> String { infoValue(forKey: "IAPOneTime", fallback: "com.test.new.nonconsumable1") }
    func iAPIWeekly() -> String { infoValue(forKey: "IAPWeekly", fallback: "com.test.new.weekly") }
    func iAPMonthly() -> String { infoValue(forKey: "IAPMonthly", fallback: "com.test.new.monthly") }
    func iAPYearly() -> String { infoValue(forKey: "IAPYearly", fallback: "com.test.new.yearly") }
    
    // MARK: LocalNotification
    func enableLocalNotification() -> Bool { boolValue(forKey: "EnableLocalNotification", fallback: false) }
    func timeTriggerNotification() -> TimeInterval {
        if let val: String = infoValue(forKey: "TimeTriggerNotification", fallback: ""), let interval = TimeInterval(val) {
            return interval
        }
        return 81600
    }
}
