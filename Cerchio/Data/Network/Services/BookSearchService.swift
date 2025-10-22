//
//  BookSearchService.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation
import RxSwift

// MARK: - Book Search Service Protocol

protocol BookSearchServiceProtocol {
    func searchBooks(query: String, display: Int?, start: Int?, sort: BookSearchSort?) -> Observable<BookSearchResponse>
    func searchBooks(request: BookSearchRequest) -> Observable<BookSearchResponse>
}

// MARK: - Book Search Service Implementation

final class BookSearchService: BaseService<BookSearchService.Dependencies>, BookSearchServiceProtocol {

    struct Dependencies: ServiceDependencies {
        let networkClient: NetworkClientProtocol
    }

    // MARK: - Public Methods

    func searchBooks(
        query: String,
        display: Int? = nil,
        start: Int? = nil,
        sort: BookSearchSort? = nil
    ) -> Observable<BookSearchResponse> {
        let request = BookSearchRequest(
            query: query,
            display: display,
            start: start,
            sort: sort
        )
        return searchBooks(request: request)
    }

    func searchBooks(request: BookSearchRequest) -> Observable<BookSearchResponse> {
        let networkRequest = BookSearchNetworkRequest(searchRequest: request)

        return Observable.create { observer in
            do {
                try networkRequest.validate()
            } catch {
                observer.onError(error)
                return Disposables.create()
            }

            let disposable = self.networkClient
                .execute(networkRequest)
                .subscribe(
                    onNext: { response in
                        observer.onNext(response)
                        observer.onCompleted()
                    },
                    onError: { error in
                        let mappedError = self.mapNetworkError(error)
                        observer.onError(mappedError)
                    }
                )

            return disposable
        }
    }

    // MARK: - Error Handling

    private func mapNetworkError(_ error: Error) -> Error {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .serverError(let statusCode, let message):
                return mapServerError(statusCode: statusCode, message: message)
            case .unauthorized:
                return BookSearchError.incorrectQuery
            case .forbidden:
                return BookSearchError.incorrectQuery
            case .notFound:
                return BookSearchError.invalidSearchAPI
            case .rateLimited:
                return BookSearchError.systemError
            case .serviceUnavailable:
                return BookSearchError.systemError
            default:
                return BookSearchError.systemError
            }
        }
        return error
    }

    private func mapServerError(statusCode: Int, message: String?) -> BookSearchError {
        if let messageData = message?.data(using: .utf8),
           let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: messageData) {
            return BookSearchError.fromErrorCode(errorResponse.errorCode)
        }

        switch statusCode {
        case 400:
            return .incorrectQuery
        case 404:
            return .invalidSearchAPI
        case 500:
            return .systemError
        default:
            return .unknownError("HTTP \(statusCode): \(message ?? "Unknown error")")
        }
    }
}

// MARK: - Convenience Extensions

extension BookSearchService {

    func searchFirstPage(query: String, display: Int = BookSearchConstants.defaultDisplay) -> Observable<BookSearchResponse> {
        return searchBooks(
            query: query,
            display: display,
            start: BookSearchConstants.defaultStart,
            sort: .accuracy
        )
    }

    func searchNextPage(query: String, currentStart: Int, display: Int = BookSearchConstants.defaultDisplay) -> Observable<BookSearchResponse> {
        let nextStart = currentStart + display
        guard nextStart <= BookSearchConstants.maxStart else {
            return Observable.error(BookSearchError.invalidStartValue)
        }

        return searchBooks(
            query: query,
            display: display,
            start: nextStart,
            sort: .accuracy
        )
    }

    func searchWithPagination(
        query: String,
        pageNumber: Int,
        pageSize: Int = BookSearchConstants.defaultDisplay
    ) -> Observable<BookSearchResponse> {
        let start = (pageNumber - 1) * pageSize + 1
        return searchBooks(
            query: query,
            display: pageSize,
            start: start,
            sort: .accuracy
        )
    }
}

// MARK: - Mock Implementation

final class MockBookSearchService: BookSearchServiceProtocol {

    enum MockScenario {
        case success
        case emptyResult
        case networkError
        case invalidQuery
    }

    private let scenario: MockScenario
    private let delay: TimeInterval

    init(scenario: MockScenario = .success, delay: TimeInterval = 1.0) {
        self.scenario = scenario
        self.delay = delay
    }

    func searchBooks(query: String, display: Int?, start: Int?, sort: BookSearchSort?) -> Observable<BookSearchResponse> {
        let request = BookSearchRequest(query: query, display: display, start: start, sort: sort)
        return searchBooks(request: request)
    }

    func searchBooks(request: BookSearchRequest) -> Observable<BookSearchResponse> {
        return Observable.create { observer in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                switch self.scenario {
                case .success:
                    let mockResponse = self.createMockResponse()
                    observer.onNext(mockResponse)
                    observer.onCompleted()

                case .emptyResult:
                    let emptyResponse = BookSearchResponse(
                        lastBuildDate: "",
                        total: 0,
                        start: 1,
                        display: 10,
                        items: []
                    )
                    observer.onNext(emptyResponse)
                    observer.onCompleted()

                case .networkError:
                    observer.onError(BookSearchError.systemError)

                case .invalidQuery:
                    observer.onError(BookSearchError.incorrectQuery)
                }
            }
            return Disposables.create()
        }
    }

    private func createMockResponse() -> BookSearchResponse {
        let mockItems = [
            BookSearchItem(
                title: "테스트 도서 1",
                link: "https://example.com/book1",
                image: "https://example.com/image1.jpg",
                author: "테스트 작가",
                discount: "15000",
                publisher: "테스트 출판사",
                isbn: "1234567890123",
                description: "테스트 도서 설명",
                pubdate: "20240101"
            )
        ]

        return BookSearchResponse(
            lastBuildDate: "2024-01-01T00:00:00Z",
            total: 1,
            start: 1,
            display: 10,
            items: mockItems
        )
    }
}
