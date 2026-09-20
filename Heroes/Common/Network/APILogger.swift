//
//  APILogger.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Moya
import Alamofire

enum APILogger {
    static var plugin: PluginType {
        APILoggerPlugin()
    }

    static func logRequest(_ request: URLRequest?, target: TargetType) {
        #if DEBUG
        let method = request?.httpMethod ?? target.method.rawValue
        let url = request?.url?.absoluteString ?? target.baseURL.appendingPathComponent(target.path).absoluteString
        print("\n🚀 [API REQUEST] ==================================")
        print("URL: \(url)")
        print("Method: \(method)")
        if let headers = request?.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers: \(headers)")
        }
        if let body = request?.httpBody, let bodyString = preview(data: body) {
            print("Body: \(bodyString)")
        }
        print("===================================================\n")
        #endif
    }

    static func logResponse(_ response: Moya.Response, target: TargetType) {
        #if DEBUG
        let url = response.request?.url?.absoluteString ?? target.baseURL.appendingPathComponent(target.path).absoluteString
        print("\n✅ [API RESPONSE] ==================================")
        print("Status Code: \(response.statusCode)")
        print("URL: \(url)")
        if let bodyString = preview(data: response.data) {
            print("Response Data: \(bodyString)")
        }
        print("===================================================\n")
        #endif
    }

    static func logError(_ error: Error, target: TargetType?) {
        #if DEBUG
        print("\n❌ [API ERROR] =====================================")
        if let apiError = error as? APIError {
            print("Error Description: \(apiError.localizedDescription)")
        } else {
            print("Error Description: \(error.localizedDescription)")
        }
        print("===================================================\n")
        #endif
    }

    private static func preview(data: Data, limit: Int = 2_000) -> String? {
        guard !data.isEmpty else { return nil }
        let clippedData = data.count > limit ? Data(data.prefix(limit)) : data
        guard var text = String(data: clippedData, encoding: .utf8) else {
            return "<\(data.count) bytes>"
        }
        if data.count > limit {
            text += "... <truncated \(data.count - limit) bytes>"
        }
        return text
    }
}

private final class APILoggerPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        APILogger.logRequest(request.request, target: target)
    }

    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        if case .success(let response) = result {
            APILogger.logResponse(response, target: target)
        }
    }
}
