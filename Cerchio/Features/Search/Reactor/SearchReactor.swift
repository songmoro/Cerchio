//
//  SearchReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import ReactorKit
import RxSwift
import RealmSwift
import FirebaseAnalytics

final class SearchReactor: Reactor {
    enum Action {
        case searchTextChanged(String)
        case searchButtonTapped
        case addBookToLibrary(Book)
        case loadMore
        case refresh
        case loadSearchHistory
        case selectSearchHistory(String)
    }

    enum Mutation {
        case setSearchText(String)
        case setSearchState(SearchState)
        case setLoading(Bool)
        case setError(String?)
        case setOriginalSearchItems([BookSearchItem])
        case setLastSavedBook(Book?)
        case appendSearchResults([Book], [BookSearchItem])
        case setCurrentPage(Int)
        case setHasMore(Bool)
        case setIsLoadingMore(Bool)
        case refreshSearchResults([Book], [BookSearchItem])
        case setSearchHistory([String])
        case setIsSearching(Bool)
    }

    struct State {
        var searchText: String = ""
        var searchState: SearchState = .initial
        var isLoading: Bool = false
        var error: String?
        var originalSearchItems: [BookSearchItem] = []
        var lastSavedBook: Book?
        var currentPage: Int = 1
        var hasMore: Bool = false
        var isLoadingMore: Bool = false
        var searchHistory: [String] = []
        var isSearching: Bool = false
    }
    
    let initialState = State()

    private let bookSearchService: BookSearchServiceProtocol
    private let bookRepository: BookRepositoryProtocol
    private let searchHistoryRepository: SearchHistoryRepositoryProtocol

    init(bookSearchService: BookSearchServiceProtocol, bookRepository: BookRepositoryProtocol, searchHistoryRepository: SearchHistoryRepositoryProtocol) {
        self.bookSearchService = bookSearchService
        self.bookRepository = bookRepository
        self.searchHistoryRepository = searchHistoryRepository
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .searchTextChanged(let text):
            return Observable.just(.setSearchText(text))

        case .searchButtonTapped:
            // 이미 검색 중이면 무시
            guard !currentState.isSearching else {
                return Observable.empty()
            }

            let searchText = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !searchText.isEmpty else {
                return Observable.just(.setSearchState(.initial))
            }

            Analytics.logEvent("search_performed", parameters: [
                "search_query": searchText
            ])

            return Observable.concat([
                Observable.just(.setIsSearching(true)),
                Observable.just(.setLoading(true)),
                Observable.just(.setSearchState(.searching)),
                Observable.just(.setCurrentPage(1)),
                saveSearchHistory(keyword: searchText),
                reloadSearchHistory(),  // 검색 이력 먼저 갱신
                performSearch(query: searchText, page: 1),
                Observable.just(.setLoading(false)),
                Observable.just(.setIsSearching(false))
            ])

        case .loadMore:
            guard !currentState.isLoadingMore,
                  currentState.hasMore else {
                return Observable.empty()
            }

            let searchText = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextPage = currentState.currentPage + 1

            return Observable.concat([
                Observable.just(.setIsLoadingMore(true)),
                performSearch(query: searchText, page: nextPage, isLoadMore: true),
                Observable.just(.setIsLoadingMore(false))
            ])

        case .refresh:
            guard case .results(let books, let items) = currentState.searchState else {
                return Observable.empty()
            }

            return Observable.from(books.map { $0.isbn })
                .flatMap { [weak self] isbn -> Observable<Bool> in
                    guard let self = self else { return Observable.just(false) }
                    return self.bookRepository.bookExistsByISBN(isbn)
                }
                .toArray()
                .asObservable()
                .map { existsArray -> Mutation in
                    let refreshedBooks = zip(books, existsArray).map { book, exists -> Book in
                        return book
                    }
                    return .refreshSearchResults(refreshedBooks, items)
                }
                .catch { _ in Observable.empty() }

        case .addBookToLibrary(let book):
            return bookRepository.bookExistsByISBN(book.isbn)
                .flatMap { [weak self] exists -> Observable<Mutation> in
                    guard let self = self else { return Observable.just(.setError("내부 오류")) }

                    if exists {
                        return Observable.just(.setError("이미 서재에 있는 책입니다."))
                    }

                    let originalItems = self.currentState.originalSearchItems

                    if let matchingItem = originalItems.first(where: { $0.isbn == book.isbn }) {
                        let realmBook = matchingItem.toRealmBook()

                        Analytics.logEvent("book_added_to_library", parameters: [
                            "book_title": realmBook.cleanTitle,
                            "book_isbn": realmBook.isbn
                        ])

                        return self.saveBookWithRepository(realmBook)
                            .do(onNext: { success in
                                if success {
                                } else {
                                }
                            })
                            .flatMap { success -> Observable<Mutation> in
                                guard success else {
                                    return Observable.just(.setError(nil))
                                }
                                return self.bookRepository.getBookByISBN(book.isbn)
                                    .flatMap { savedBook -> Observable<Mutation> in
                                        if let savedBook = savedBook {
                                            return Observable.concat([
                                                Observable.just(.setLastSavedBook(savedBook)),
                                                Observable.just(.setError(nil))
                                            ])
                                        } else {
                                            return Observable.just(.setError(nil))
                                        }
                                    }
                            }
                    } else {
                        return Observable.just(.setError("원본 데이터를 찾을 수 없습니다."))
                    }
                }

        case .loadSearchHistory:
            return searchHistoryRepository.getAllSearchHistory()
                .take(10)
                .map { history in
                    let keywords = Array(history.prefix(10)).map { $0.keyword }
                    return .setSearchHistory(keywords)
                }
                .catch { _ in Observable.just(.setSearchHistory([])) }

        case .selectSearchHistory(let keyword):
            return Observable.just(.setSearchText(keyword))
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

        case .setLastSavedBook(let book):
            newState.lastSavedBook = book

        case .appendSearchResults(let books, let items):
            if case .results(var existingBooks, var existingItems) = newState.searchState {
                existingBooks.append(contentsOf: books)
                existingItems.append(contentsOf: items)
                newState.searchState = .results(existingBooks, existingItems)
                newState.originalSearchItems.append(contentsOf: items)
            }

        case .setCurrentPage(let page):
            newState.currentPage = page

        case .setHasMore(let hasMore):
            newState.hasMore = hasMore

        case .setIsLoadingMore(let isLoadingMore):
            newState.isLoadingMore = isLoadingMore

        case .refreshSearchResults(let books, let items):
            newState.searchState = .results(books, items)
            newState.originalSearchItems = items

        case .setSearchHistory(let keywords):
            newState.searchHistory = keywords

        case .setIsSearching(let isSearching):
            newState.isSearching = isSearching
        }

        return newState
    }

    // MARK: - Helper Methods

    private func reloadSearchHistory() -> Observable<Mutation> {
        return searchHistoryRepository.getAllSearchHistory()
            .take(10)
            .map { history in
                let keywords = Array(history.prefix(10)).map { $0.keyword }
                return .setSearchHistory(keywords)
            }
            .catch { _ in Observable.just(.setSearchHistory([])) }
    }

    private func saveSearchHistory(keyword: String) -> Observable<Mutation> {
        return searchHistoryRepository.saveSearchHistory(keyword: keyword)
            .map { _ in .setError(nil) }
            .catch { error in
                print(" 검색 이력 저장 실패: \(error.localizedDescription)")
                return Observable.just(.setError(nil))
            }
    }

    private func performSearch(query: String, page: Int, isLoadMore: Bool = false) -> Observable<Mutation> {
        let display = 100
        let start = (page - 1) * display + 1

        return bookSearchService
            .searchBooks(query: query, display: display, start: start, sort: .accuracy)
            .flatMap { [weak self] response -> Observable<Mutation> in
                guard self != nil else { return Observable.empty() }
                let books = BookSearchMapper.mapResponseToBooks(response)
                let originalItems = response.items
                let hasMore = response.start + response.display <= response.total

                if isLoadMore {
                    if books.isEmpty {
                        return Observable.concat([
                            Observable.just(.setHasMore(false))
                        ])
                    } else {
                        return Observable.concat([
                            Observable.just(.appendSearchResults(books, originalItems)),
                            Observable.just(.setCurrentPage(page)),
                            Observable.just(.setHasMore(hasMore))
                        ])
                    }
                } else {
                    if books.isEmpty {
                        return Observable.concat([
                            Observable.just(.setOriginalSearchItems([])),
                            Observable.just(.setSearchState(.noResults)),
                            Observable.just(.setHasMore(false))
                        ])
                    } else {
                        return Observable.concat([
                            Observable.just(.setOriginalSearchItems(originalItems)),
                            Observable.just(.setSearchState(.results(books, originalItems))),
                            Observable.just(.setHasMore(hasMore))
                        ])
                    }
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
                    Observable.just(.setSearchState(.error(errorMessage))),
                    Observable.just(.setHasMore(false))
                ])
            }
    }

    private func saveBookWithRepository(_ realmBook: RealmBook) -> Observable<Bool> {
        return bookRepository.saveBook(realmBook)
            .map { _ in true }
            .catch { error in
                print(" Failed to save book: \(error.localizedDescription)")
                return Observable.just(false)
            }
    }
}
