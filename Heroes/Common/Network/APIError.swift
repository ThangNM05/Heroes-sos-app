//
//  APIError.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Moya
import Alamofire

struct APIError: Error, LocalizedError {
    var description: String
    let statusCode: Int?
    let serverCode: String?
    let serverMessage: String?
    let retryAfter: TimeInterval?
    let requestURL: URL?
    let responseData: Data?
    let underlyingError: Error?

    var errorDescription: String? {
        description
    }

    static func invalidURL(baseURL: String, path: String) -> APIError {
        APIError(
            description: "Invalid API URL: \(baseURL) \(path)",
            statusCode: nil,
            serverCode: nil,
            serverMessage: nil,
            retryAfter: nil,
            requestURL: nil,
            responseData: nil,
            underlyingError: nil
        )
    }

    static func httpStatus(_ response: Moya.Response, target: TargetType) -> APIError {
        let statusMessage = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        let serverError = try? APICoding.makeDecoder().decode(APIErrorEnvelope.self, from: response.data)
        let message = serverError?.data?.message ?? "API request failed with status \(response.statusCode): \(statusMessage)"
        return APIError(
            description: message,
            statusCode: response.statusCode,
            serverCode: serverError?.data?.errorCode,
            serverMessage: serverError?.data?.message,
            retryAfter: retryAfter(from: response.response) ?? serverError?.data?.retryAfterSeconds
                ?? retryAfter(from: serverError?.data?.details),
            requestURL: requestURL(from: response, target: target),
            responseData: response.data,
            underlyingError: nil
        )
    }

    static func decoding(_ error: Error, response: Moya.Response, target: TargetType) -> APIError {
        APIError(
            description: "API decode failed: \(error.localizedDescription)",
            statusCode: response.statusCode,
            serverCode: nil,
            serverMessage: nil,
            retryAfter: nil,
            requestURL: requestURL(from: response, target: target),
            responseData: response.data,
            underlyingError: error
        )
    }

    static func encoding(_ error: Error, path: String, baseURL: String = APIEndpoint.defaultBaseURL) -> APIError {
        APIError(
            description: "API encode failed: \(error.localizedDescription)",
            statusCode: nil,
            serverCode: nil,
            serverMessage: nil,
            retryAfter: nil,
            requestURL: APIEndpoint.url(path: path, baseURL: baseURL),
            responseData: nil,
            underlyingError: error
        )
    }

    static func transport(_ error: Error, target: TargetType?) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        if let moyaError = error as? MoyaError {
            return APIError(
                description: "API request error: \(moyaError.localizedDescription)",
                statusCode: moyaError.response?.statusCode,
                serverCode: moyaError.response.flatMap { response in
                    (try? APICoding.makeDecoder().decode(APIErrorEnvelope.self, from: response.data))?.data?.errorCode
                },
                serverMessage: moyaError.response.flatMap { response in
                    (try? APICoding.makeDecoder().decode(APIErrorEnvelope.self, from: response.data))?.data?.message
                },
                retryAfter: moyaError.response.flatMap { retryAfter(from: $0.response) },
                requestURL: moyaError.response.flatMap { response in
                    target.flatMap { requestURL(from: response, target: $0) }
                },
                responseData: moyaError.response?.data,
                underlyingError: moyaError
            )
        }

        return APIError(
            description: "API request error: \(error.localizedDescription)",
            statusCode: nil,
            serverCode: nil,
            serverMessage: nil,
            retryAfter: nil,
            requestURL: nil,
            responseData: nil,
            underlyingError: error
        )
    }

    private static func requestURL(from response: Moya.Response, target: TargetType) -> URL? {
        response.request?.url ?? APIEndpoint.url(path: target.path, baseURL: target.baseURL.absoluteString)
    }

    private static func retryAfter(from response: HTTPURLResponse?) -> TimeInterval? {
        guard let value = response?.value(forHTTPHeaderField: "Retry-After") else { return nil }
        if let seconds = TimeInterval(value) {
            return seconds
        }
        return nil
    }

    private static func retryAfter(from details: JSONValue?) -> TimeInterval? {
        guard case .object(let fields) = details,
              case .number(let seconds) = fields["retryAfterSeconds"] else { return nil }
        return seconds
    }
}
