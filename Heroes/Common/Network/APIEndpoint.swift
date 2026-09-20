//
//  APIEndpoint.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Moya
import Alamofire

struct APIEndpoint: TargetType {
    static var defaultBaseURL: String {
        Configs.Network.baseURL
    }

    let baseURLString: String
    let path: String
    let method: Moya.Method
    let task: Task
    let headers: [String: String]?
    let sampleData: Data

    var baseURL: URL {
        URL(string: baseURLString) ?? URL(string: "https://invalid.local")!
    }

    var isValidBaseURL: Bool {
        URL(string: baseURLString) != nil
    }

    init(
        path: String,
        method: Moya.Method = .get,
        baseURL: String = APIEndpoint.defaultBaseURL,
        task: Task = .requestPlain,
        headers: [String: String]? = ["Accept": "application/json"],
        sampleData: Data = Data()
    ) {
        self.baseURLString = baseURL
        self.path = path
        self.method = method
        self.task = task
        self.headers = headers
        self.sampleData = sampleData
    }

    static func request(
        path: String,
        method: Moya.Method = .get,
        baseURL: String = APIEndpoint.defaultBaseURL,
        queryItems: [URLQueryItem] = [],
        headers: [String: String]? = ["Accept": "application/json"],
        body: Data? = nil
    ) -> APIEndpoint {
        var parameters: [String: Any] = [:]
        queryItems.forEach { item in
            parameters[item.name] = item.value ?? ""
        }

        let task: Task
        switch (body, parameters.isEmpty) {
        case (.none, true):
            task = .requestPlain
        case (.none, false):
            task = .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case (.some(let bodyData), true):
            task = .requestData(bodyData)
        case (.some(let bodyData), false):
            task = .requestCompositeData(bodyData: bodyData, urlParameters: parameters)
        }

        return APIEndpoint(
            path: path,
            method: method,
            baseURL: baseURL,
            task: task,
            headers: headers
        )
    }

    static func url(
        path: String,
        baseURL: String = APIEndpoint.defaultBaseURL,
        queryItems: [URLQueryItem] = []
    ) -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpointPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch (basePath.isEmpty, endpointPath.isEmpty) {
        case (true, true):
            components.path = ""
        case (true, false):
            components.path = "/" + endpointPath
        case (false, true):
            components.path = "/" + basePath
        case (false, false):
            components.path = "/" + basePath + "/" + endpointPath
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}
