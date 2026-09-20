//
//  INetworkClient.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Moya
import Alamofire

protocol INetworkClient: AnyObject {
    func response(_ target: TargetType) async throws -> Moya.Response
    func data(_ target: TargetType) async throws -> Data
    func request<T: Decodable>(_ target: TargetType, decoder: JSONDecoder) async throws -> T
}

extension INetworkClient {
    func request<T: Decodable>(
        path: String,
        method: Moya.Method = .get,
        baseURL: String = APIEndpoint.defaultBaseURL,
        queryItems: [URLQueryItem] = [],
        headers: [String: String]? = ["Accept": "application/json"],
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let target = APIEndpoint.request(
            path: path,
            method: method,
            baseURL: baseURL,
            queryItems: queryItems,
            headers: headers,
            body: body
        )

        guard target.isValidBaseURL else {
            throw APIError.invalidURL(baseURL: baseURL, path: path)
        }

        return try await request(target, decoder: decoder)
    }

    func request<T: Decodable, Body: Encodable>(
        path: String,
        method: Moya.Method = .post,
        baseURL: String = APIEndpoint.defaultBaseURL,
        queryItems: [URLQueryItem] = [],
        headers: [String: String]? = ["Accept": "application/json"],
        jsonBody: Body,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        do {
            let body = try encoder.encode(jsonBody)
            var nextHeaders = headers ?? [:]
            if nextHeaders["Content-Type"] == nil {
                nextHeaders["Content-Type"] = "application/json"
            }
            if nextHeaders["Accept"] == nil {
                nextHeaders["Accept"] = "application/json"
            }

            return try await request(
                path: path,
                method: method,
                baseURL: baseURL,
                queryItems: queryItems,
                headers: nextHeaders,
                body: body,
                decoder: decoder
            )
        } catch {
            let apiError = APIError.encoding(error, path: path, baseURL: baseURL)
            APILogger.logError(apiError, target: nil)
            throw apiError
        }
    }

    func uploadMultipart(
        path: String,
        parts: [Moya.MultipartFormData],
        baseURL: String = APIEndpoint.defaultBaseURL,
        headers: [String: String]? = ["Accept": "*/*"]
    ) async throws -> Data {
        let target = APIEndpoint(
            path: path,
            method: .post,
            baseURL: baseURL,
            task: .uploadMultipart(parts),
            headers: headers
        )

        guard target.isValidBaseURL else {
            throw APIError.invalidURL(baseURL: baseURL, path: path)
        }

        return try await data(target)
    }
}
