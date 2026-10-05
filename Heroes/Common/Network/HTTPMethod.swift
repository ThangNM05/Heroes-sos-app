//
//  HTTPMethod.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum HTTPStatus {
    static func isSuccess(_ code: Int) -> Bool {
        (200..<300).contains(code)
    }

    static func isUnauthorized(_ code: Int) -> Bool {
        code == 401
    }

    static func isRateLimited(_ code: Int) -> Bool {
        code == 429
    }

    static func isRetryable(_ code: Int) -> Bool {
        code == 408 || code == 429 || (500..<600).contains(code)
    }
}
