//
//  BookSearchModels.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

struct BookSearchRequest {
    let query: String
    let display: Int?
    let start: Int?
    let sort: BookSearchSort?

    init(query: String, display: Int? = nil, start: Int? = nil, sort: BookSearchSort? = nil) {
        self.query = query
        self.display = display
        self.start = start
        self.sort = sort
    }
}

enum BookSearchSort: String, CaseIterable {
    case accuracy = "sim"
    case date = "date"

    var displayName: String {
        switch self {
        case .accuracy: return "정확도순"
        case .date: return "출간일순"
        }
    }
}

struct BookSearchResponse: Codable {
    let lastBuildDate: String
    let total: Int
    let start: Int
    let display: Int
    let items: [BookSearchItem]
}

struct BookSearchItem: Codable {
    let title: String
    let link: String
    let image: String
    let author: String
    let discount: String?
    let publisher: String
    let isbn: String
    let description: String
    let pubdate: String

    var cleanTitle: String {
        return title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    var cleanDescription: String {
        return description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    var formattedPubDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: pubdate)
    }

    var formattedPrice: String? {
        guard let discount = discount else { return nil }
        return discount
    }

    var priceAsInt: Int? {
        guard let discount = discount else { return nil }
        return Int(discount)
    }
}

enum BookSearchError: Error, LocalizedError {
    case incorrectQuery
    case invalidDisplayValue
    case invalidStartValue
    case invalidSortValue
    case malformedEncoding
    case invalidSearchAPI
    case systemError
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .incorrectQuery:
            return "잘못된 쿼리 요청입니다."
        case .invalidDisplayValue:
            return "부적절한 display 값입니다. (1~100)"
        case .invalidStartValue:
            return "부적절한 start 값입니다. (1~1000)"
        case .invalidSortValue:
            return "부적절한 sort 값입니다."
        case .malformedEncoding:
            return "잘못된 형식의 인코딩입니다."
        case .invalidSearchAPI:
            return "존재하지 않는 검색 API입니다."
        case .systemError:
            return "시스템 에러가 발생했습니다."
        case .unknownError(let message):
            return "알 수 없는 오류: \(message)"
        }
    }

    static func fromErrorCode(_ code: String) -> BookSearchError {
        switch code {
        case "SE01": return .incorrectQuery
        case "SE02": return .invalidDisplayValue
        case "SE03": return .invalidStartValue
        case "SE04": return .invalidSortValue
        case "SE05": return .invalidSearchAPI
        case "SE06": return .malformedEncoding
        case "SE99": return .systemError
        default: return .unknownError(code)
        }
    }
}

struct APIErrorResponse: Codable {
    let errorMessage: String
    let errorCode: String
}

enum BookSearchConstants {
    static let baseURL = "https://openapi.naver.com/v1/search/book.json"
    static let defaultDisplay = 10
    static let maxDisplay = 100
    static let minDisplay = 1
    static let defaultStart = 1
    static let maxStart = 1000
    static let minStart = 1

    enum Headers {
        static let clientId = "X-Naver-Client-Id"
        static let clientSecret = "X-Naver-Client-Secret"
        static let accept = "Accept"
        static let contentType = "Content-Type"
    }

    enum Values {
        static let accept = "application/json"
        static let contentType = "application/json"
    }
}
