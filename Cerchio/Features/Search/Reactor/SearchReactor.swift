//
//  SearchReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import ReactorKit
import RxSwift

final class SearchReactor: Reactor {
    enum Action {
        case searchTextChanged(String)
        case searchButtonTapped
        case addBookToLibrary(Book)
    }

    enum Mutation {
        case setSearchText(String)
        case setSearchState(SearchState)
        case setLoading(Bool)
        case setError(String?)
        case setOriginalSearchItems([BookSearchItem])
    }

    struct State {
        var searchText: String = ""
        var searchState: SearchState = .initial
        var isLoading: Bool = false
        var error: String?
        var originalSearchItems: [BookSearchItem] = []  // 원본 데이터 보존
    }
    
    let initialState = State()

    private let bookSearchService: BookSearchServiceProtocol

    init(bookSearchService: BookSearchServiceProtocol) {
        self.bookSearchService = bookSearchService
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .searchTextChanged(let text):
            return Observable.just(.setSearchText(text))

        case .searchButtonTapped:
            let searchText = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !searchText.isEmpty else {
                return Observable.just(.setSearchState(.initial))
            }

            return Observable.concat([
                Observable.just(.setLoading(true)),
                Observable.just(.setSearchState(.searching)),
                performSearch(query: searchText),
                Observable.just(.setLoading(false))
            ])

        case .addBookToLibrary(let book):
            // TODO: BookService를 통한 도서 추가 로직
            print(book)
            print("책 추가: \(book.title)")
            return Observable.empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setSearchText(let text):
            newState.searchText = text

        case .setSearchState(let searchState):
            newState.searchState = searchState

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error

        case .setOriginalSearchItems(let items):
            newState.originalSearchItems = items
        }

        return newState
    }

    // MARK: - Private Methods
    private func performSearch(query: String) -> Observable<Mutation> {
        return bookSearchService
            .searchBooks(query: query, display: 100, start: 1, sort: .accuracy)
            .flatMap { response -> Observable<Mutation> in
                let books = BookSearchMapper.mapResponseToBooks(response)
                let originalItems = response.items

                if books.isEmpty {
                    return Observable.concat([
                        Observable.just(.setOriginalSearchItems([])),
                        Observable.just(.setSearchState(.noResults))
                    ])
                } else {
                    return Observable.concat([
                        Observable.just(.setOriginalSearchItems(originalItems)),
                        Observable.just(.setSearchState(.results(books, originalItems)))
                    ])
                }
            }
            .catch { error in
                let errorMessage: String
                if let bookSearchError = error as? BookSearchError {
                    errorMessage = bookSearchError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                return Observable.concat([
                    Observable.just(.setOriginalSearchItems([])),
                    Observable.just(.setSearchState(.error(errorMessage)))
                ])
            }
    }
}
