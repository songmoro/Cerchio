//
//  BookSearchNetworkRequest.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

struct BookSearchNetworkRequest: NetworkRequest {
    typealias Response = BookSearchResponse

    private let searchRequest: BookSearchRequest

    init(searchRequest: BookSearchRequest) {
        self.searchRequest = searchRequest
    }

    var baseURL: URL {
        guard let url = URL(string: BookSearchConstants.baseURL) else {
            fatalError("Invalid BookSearch base URL: \(BookSearchConstants.baseURL)")
        }
        return url
    }

    var path: String {
        return ""
    }

    var method: HTTPMethod {
        return .GET
    }

    var queryParameters: [String: String]? {
        var parameters: [String: String] = [
            "query": searchRequest.query
        ]

        if let display = searchRequest.display {
            let clampedDisplay = max(BookSearchConstants.minDisplay,
                                   min(BookSearchConstants.maxDisplay, display))
            parameters["display"] = String(clampedDisplay)
        }

        if let start = searchRequest.start {
            let clampedStart = max(BookSearchConstants.minStart,
                                 min(BookSearchConstants.maxStart, start))
            parameters["start"] = String(clampedStart)
        }

        if let sort = searchRequest.sort {
            parameters["sort"] = sort.rawValue
        }

        return parameters
    }

    var headers: [String: String]? {
        return [
            BookSearchConstants.Headers.clientId: APIKey.XNaverClientId,
            BookSearchConstants.Headers.clientSecret: APIKey.XNaverClientSecret,
            BookSearchConstants.Headers.accept: BookSearchConstants.Values.accept,
            BookSearchConstants.Headers.contentType: BookSearchConstants.Values.contentType
        ]
    }

    var body: Data? {
        return nil
    }

    var timeout: TimeInterval {
        return NetworkConstants.defaultTimeout
    }
}

extension BookSearchNetworkRequest {

    func validate() throws {
        guard !searchRequest.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BookSearchError.incorrectQuery
        }

        if let display = searchRequest.display {
            guard display >= BookSearchConstants.minDisplay && display <= BookSearchConstants.maxDisplay else {
                throw BookSearchError.invalidDisplayValue
            }
        }

        if let start = searchRequest.start {
            guard start >= BookSearchConstants.minStart && start <= BookSearchConstants.maxStart else {
                throw BookSearchError.invalidStartValue
            }
        }

        guard !APIKey.XNaverClientId.isEmpty && !APIKey.XNaverClientSecret.isEmpty else {
            throw BookSearchError.incorrectQuery
        }
    }
}

struct BookSearchRequestBuilder {
    private var query: String = ""
    private var display: Int?
    private var start: Int?
    private var sort: BookSearchSort?

    func setQuery(_ query: String) -> BookSearchRequestBuilder {
        var builder = self
        builder.query = query
        return builder
    }

    func setDisplay(_ display: Int) -> BookSearchRequestBuilder {
        var builder = self
        builder.display = display
        return builder
    }

    func setStart(_ start: Int) -> BookSearchRequestBuilder {
        var builder = self
        builder.start = start
        return builder
    }

    func setSort(_ sort: BookSearchSort) -> BookSearchRequestBuilder {
        var builder = self
        builder.sort = sort
        return builder
    }

    func build() -> BookSearchRequest {
        return BookSearchRequest(
            query: query,
            display: display,
            start: start,
            sort: sort
        )
    }
}

extension BookSearchNetworkRequest {

    static func search(
        query: String,
        display: Int = BookSearchConstants.defaultDisplay,
        start: Int = BookSearchConstants.defaultStart,
        sort: BookSearchSort = .accuracy
    ) -> BookSearchNetworkRequest {
        let searchRequest = BookSearchRequest(
            query: query,
            display: display,
            start: start,
            sort: sort
        )
        return BookSearchNetworkRequest(searchRequest: searchRequest)
    }

    static func searchWithBuilder(_ builder: (BookSearchRequestBuilder) -> BookSearchRequestBuilder) -> BookSearchNetworkRequest {
        let searchRequest = builder(BookSearchRequestBuilder()).build()
        return BookSearchNetworkRequest(searchRequest: searchRequest)
    }
}
