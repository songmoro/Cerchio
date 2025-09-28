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

    enum SearchState {
        case initial
        case searching
        case results([Book])
        case noResults
        case error(String)
    }

    let initialState = State()

    // TODO: BookService 추가 시 의존성 주입
    // private let bookService: BookServiceType

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
        // TODO: 실제 BookService로 교체
        return mockSearchAPI(query: query)
            .map { books in
                if books.isEmpty {
                    return .setSearchState(.noResults)
                } else {
                    return .setSearchState(.results(books))
                }
            }
            .catch { error in
                Observable.just(.setSearchState(.error(error.localizedDescription)))
            }
    }

    // 임시 Mock API
    private func mockSearchAPI(query: String) -> Observable<[Book]> {
        return Observable.create { observer in
            // 1초 지연으로 네트워크 호출 시뮬레이션
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let filteredBooks = Book.sample.filter { book in
                    book.title.lowercased().contains(query.lowercased()) ||
                    book.author.lowercased().contains(query.lowercased()) ||
                    book.isbn.contains(query)
                }
                observer.onNext(filteredBooks)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}