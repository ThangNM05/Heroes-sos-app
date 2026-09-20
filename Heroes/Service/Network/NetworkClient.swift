//
//  NetworkClient.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Moya
import Alamofire

final class NetworkClient: INetworkClient {
    private let provider: MoyaProvider<MultiTarget>

    init() {
        self.provider = NetworkClient.makeProvider()
    }

    init(provider: MoyaProvider<MultiTarget>) {
        self.provider = provider
    }

    private static func makeProvider() -> MoyaProvider<MultiTarget> {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Configs.Network.networkTimeout
        configuration.timeoutIntervalForResource = Configs.Network.networkTimeout

        let session = Alamofire.Session(configuration: configuration, startRequestsImmediately: false)
        return MoyaProvider<MultiTarget>(session: session, plugins: [APILogger.plugin])
    }

    func response(_ target: TargetType) async throws -> Moya.Response {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(MultiTarget(target)) { result in
                switch result {
                case .success(let response):
                    guard (200..<300).contains(response.statusCode) else {
                        let apiError = APIError.httpStatus(response, target: target)
                        APILogger.logError(apiError, target: target)
                        continuation.resume(throwing: apiError)
                        return
                    }
                    continuation.resume(returning: response)
                case .failure(let error):
                    let apiError = APIError.transport(error, target: target)
                    APILogger.logError(apiError, target: target)
                    continuation.resume(throwing: apiError)
                }
            }
        }
    }

    func data(_ target: TargetType) async throws -> Data {
        let res = try await response(target)
        return res.data
    }

    func request<T: Decodable>(_ target: TargetType, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let res = try await response(target)
        do {
            return try decoder.decode(T.self, from: res.data)
        } catch {
            let apiError = APIError.decoding(error, response: res, target: target)
            APILogger.logError(apiError, target: target)
            throw apiError
        }
    }
}
