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
            requestURL: nil,
            responseData: nil,
            underlyingError: nil
        )
    }

    static func httpStatus(_ response: Moya.Response, target: TargetType) -> APIError {
        let statusMessage = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
        return APIError(
            description: "API request failed with status \(response.statusCode): \(statusMessage)",
            statusCode: response.statusCode,
            requestURL: requestURL(from: response, target: target),
            responseData: response.data,
            underlyingError: nil
        )
    }

    static func decoding(_ error: Error, response: Moya.Response, target: TargetType) -> APIError {
        APIError(
            description: "API decode failed: \(error.localizedDescription)",
            statusCode: response.statusCode,
            requestURL: requestURL(from: response, target: target),
            responseData: response.data,
            underlyingError: error
        )
    }

    static func encoding(_ error: Error, path: String, baseURL: String = APIEndpoint.defaultBaseURL) -> APIError {
        APIError(
            description: "API encode failed: \(error.localizedDescription)",
            statusCode: nil,
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
            requestURL: nil,
            responseData: nil,
            underlyingError: error
        )
    }

    private static func requestURL(from response: Moya.Response, target: TargetType) -> URL? {
        response.request?.url ?? APIEndpoint.url(path: target.path, baseURL: target.baseURL.absoluteString)
    }
}
