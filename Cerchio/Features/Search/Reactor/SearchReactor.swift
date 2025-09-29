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
    }

    struct State {
        var searchText: String = ""
        var searchState: SearchState = .initial
        var isLoading: Bool = false
        var error: String?
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
        }

        return newState
    }

    // MARK: - Private Methods
    private func performSearch(query: String) -> Observable<Mutation> {
        return bookSearchService
            .searchBooks(query: query, display: 100, start: 1, sort: .accuracy)
            .map { response -> [Book] in
                return BookSearchMapper.mapResponseToBooks(response)
            }
            .map { books in
                if books.isEmpty {
                    return .setSearchState(.noResults)
                } else {
                    return .setSearchState(.results(books))
                }
            }
            .catch { error in
                let errorMessage: String
                if let bookSearchError = error as? BookSearchError {
                    errorMessage = bookSearchError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                return Observable.just(.setSearchState(.error(errorMessage)))
            }
    }
}
