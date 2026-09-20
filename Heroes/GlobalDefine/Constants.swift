//
//  Constants.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import UIKit

final class Constants {
    enum AppInfo {
        static var AppName: String {
            (Bundle.main.object(forInfoDictionaryKey: "AppName") as? String)
            ?? (Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String)
            ?? "BaseProject"
        }
        
        static var AppVersion: String {
            (Bundle.main.object(forInfoDictionaryKey: "BundleVersionString") as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
            ?? "1.0"
        }
        
        static var AppBuild: String {
            (Bundle.main.object(forInfoDictionaryKey: "BundleVersion") as? String)
            ?? (Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String)
            ?? "1"
        }
    }

    static var APP_STORE_URL: String {
        "https://apps.apple.com/app/\(Configs.InfoApp.appId)"
    }
    
    static let maxRetryCount = 5

    enum API {
        static var defaultBaseURL: String {
            Configs.Server.baseURL
        }
    }
}
