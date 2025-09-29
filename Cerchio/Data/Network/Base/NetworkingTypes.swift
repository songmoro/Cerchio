//
//  NetworkingTypes.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Request Protocol
protocol NetworkRequest {
    associatedtype Response: Decodable

    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }
    var timeout: TimeInterval { get }
}

// MARK: - Default Implementation
extension NetworkRequest {
    var baseURL: URL {
        guard let url = URL(string: NetworkConstants.baseURL) else {
            fatalError("Invalid base URL: \(NetworkConstants.baseURL)")
        }
        return url
    }

    var headers: [String: String]? {
        return NetworkConstants.defaultHeaders
    }

    var parameters: [String: Any]? {
        return nil
    }

    var queryParameters: [String: String]? {
        return nil
    }

    var body: Data? {
        return nil
    }

    var timeout: TimeInterval {
        return NetworkConstants.defaultTimeout
    }
}

// MARK: - Response Protocol
protocol NetworkResponse {
    associatedtype DataType: Decodable

    var data: DataType { get }
    var statusCode: Int { get }
    var headers: [String: String] { get }
}

// MARK: - Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case serverError(Int, String?)
    case networkError(Error)
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded"
        case .serviceUnavailable:
            return "Service unavailable"
        }
    }
}

// MARK: - Network Constants
enum NetworkConstants {
    static let baseURL = "https://api.example.com/v1"
    static let defaultTimeout: TimeInterval = 30.0
    static let defaultHeaders: [String: String] = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Cerchio/1.0"
    ]

    // MARK: - HTTP Status Codes
    enum StatusCode {
        static let successRange = 200...299
        static let badRequest = 400
        static let unauthorized = 401
        static let forbidden = 403
        static let notFound = 404
        static let rateLimited = 429
        static let serverErrorRange = 500...599
    }

    // MARK: - Error Codes
    enum ErrorCode {
        static let clientDeallocated = -1
        static let invalidResponseType = -2
        static let mockImplementation = 0
    }

    // MARK: - Retry Configuration
    enum Retry {
        static let defaultRetryCount: Int = 3
        static let defaultRetryDelay: TimeInterval = 1.0
    }
}

// MARK: - Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let data: T
    let message: String?
    let success: Bool
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case data
        case message
        case success
        case timestamp
    }
}

// MARK: - Pagination Support
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool

    enum CodingKeys: String, CodingKey {
        case items = "data"
        case totalCount = "total_count"
        case page
        case pageSize = "page_size"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
    }
}