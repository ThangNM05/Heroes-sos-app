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
        let url = sanitizedURL(request?.url)?.absoluteString
            ?? sanitizedURL(target.baseURL.appendingPathComponent(target.path))?.absoluteString
            ?? "<invalid-url>"
        print("\n🚀 [API REQUEST] ==================================")
        print("URL: \(url)")
        print("Method: \(method)")
        if let headers = request?.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers: \(sanitizedHeaders(headers))")
        }
        if shouldLogBody(contentType: request?.value(forHTTPHeaderField: "Content-Type")),
           let body = request?.httpBody,
           let bodyString = preview(data: body) {
            print("Body: \(bodyString)")
        }
        print("===================================================\n")
        #endif
    }

    static func logResponse(_ response: Moya.Response, target: TargetType) {
        #if DEBUG
        let url = sanitizedURL(response.request?.url)?.absoluteString
            ?? sanitizedURL(target.baseURL.appendingPathComponent(target.path))?.absoluteString
            ?? "<invalid-url>"
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
        guard var text = sanitizedJSONText(from: clippedData) ?? String(data: clippedData, encoding: .utf8) else {
            return "<\(data.count) bytes>"
        }
        if data.count > limit {
            text += "... <truncated \(data.count - limit) bytes>"
        }
        return text
    }

    private static func sanitizedHeaders(_ headers: [String: String]) -> [String: String] {
        let sensitiveNames = [
            "authorization", "cookie", "set-cookie", "x-heros-device-token", "x-heros-ops-token"
        ]
        return headers.mapValues { $0 }.reduce(into: [:]) { result, item in
            result[item.key] = sensitiveNames.contains(item.key.lowercased()) ? "<redacted>" : item.value
        }
    }

    private static func sanitizedURL(_ url: URL?) -> URL? {
        guard let url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        let sensitiveNames = ["code", "token", "otp", "invite", "invitationCode"]
        components.fragment = nil
        components.queryItems = components.queryItems?.map { item in
            sensitiveNames.contains(where: { $0.caseInsensitiveCompare(item.name) == .orderedSame })
                ? URLQueryItem(name: item.name, value: "<redacted>")
                : item
        }
        return components.url
    }

    private static func shouldLogBody(contentType: String?) -> Bool {
        guard let contentType else { return true }
        return !contentType.lowercased().contains("multipart/form-data")
    }

    private static func sanitizedJSONText(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let sanitized = sanitizeJSON(object),
              let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitized, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: sanitizedData, encoding: .utf8)
    }

    private static func sanitizeJSON(_ value: Any) -> Any? {
        let sensitiveNames = [
            "password", "otp", "token", "accessToken", "refreshToken", "identityToken", "challengeId",
            "rawNonce", "deviceToken", "authorization", "phone", "latitude", "longitude"
        ]

        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, item in
                if sensitiveNames.contains(where: { $0.caseInsensitiveCompare(item.key) == .orderedSame }) {
                    result[item.key] = "<redacted>"
                } else {
                    result[item.key] = sanitizeJSON(item.value) ?? NSNull()
                }
            }
        }
        if let array = value as? [Any] {
            return array.map { sanitizeJSON($0) ?? NSNull() }
        }
        return value
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
