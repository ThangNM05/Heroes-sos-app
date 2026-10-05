import Foundation

/// Standard JSON envelope returned by HEROS APIs.
struct APIResponse<Payload: Decodable>: Decodable {
    let success: Bool
    let code: Int
    let data: Payload
}

struct APIEmptyData: Codable, Equatable {
    init() {}
}

struct APIErrorEnvelope: Decodable {
    let success: Bool?
    let code: Int?
    let data: APIErrorData?
}

struct APIErrorData: Decodable {
    let errorCode: String?
    let message: String?
    let details: JSONValue?
    let retryAfterSeconds: Double?
}

enum JSONValue: Decodable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
}

enum APICoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = fractionalISO8601.date(from: value) ?? standardISO8601.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(fractionalISO8601.string(from: date))
        }
        return encoder
    }

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let standardISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

enum APIHeaders {
    static func json(accessToken: String? = nil) -> [String: String] {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        addBearer(accessToken, to: &headers)
        return headers
    }

    static func binary(accessToken: String? = nil) -> [String: String] {
        var headers = ["Accept": "*/*"]
        addBearer(accessToken, to: &headers)
        return headers
    }

    static func multipart(accessToken: String? = nil) -> [String: String] {
        // Moya generates Content-Type with the multipart boundary.
        var headers = ["Accept": "application/json"]
        addBearer(accessToken, to: &headers)
        return headers
    }

    private static func addBearer(_ accessToken: String?, to headers: inout [String: String]) {
        guard let accessToken, !accessToken.isEmpty else { return }
        headers["Authorization"] = "Bearer \(accessToken)"
    }
}
