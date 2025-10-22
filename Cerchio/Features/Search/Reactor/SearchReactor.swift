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
    }

    struct State {
        var searchText: String = ""
        var searchState: SearchState = .initial
        var isLoading: Bool = false
        var error: String?
        var originalSearchItems: [BookSearchItem] = []  // 원본 데이터 보존
        var lastSavedBook: Book?  // 마지막으로 저장된 책
        var currentPage: Int = 1
        var hasMore: Bool = false
        var isLoadingMore: Bool = false
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
            let searchText = currentState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !searchText.isEmpty else {
                return Observable.just(.setSearchState(.initial))
            }

            Analytics.logEvent("search_performed", parameters: [
                "search_query": searchText
            ])

            // 검색 이력 저장 및 첫 페이지 검색
            return Observable.concat([
                Observable.just(.setLoading(true)),
                Observable.just(.setSearchState(.searching)),
                Observable.just(.setCurrentPage(1)),
                saveSearchHistory(keyword: searchText),
                performSearch(query: searchText, page: 1),
                Observable.just(.setLoading(false))
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

        case .addBookToLibrary(let book):
            // ISBN 중복 체크 먼저 수행
            return bookRepository.bookExistsByISBN(book.isbn)
                .flatMap { [weak self] exists -> Observable<Mutation> in
                    guard let self = self else { return Observable.just(.setError("내부 오류")) }

                    if exists {
                        print(" 이미 서재에 있는 책: \(book.cleanTitle)")
                        return Observable.just(.setError("이미 서재에 있는 책입니다."))
                    }

                    // 현재 상태에서 매칭되는 원본 BookSearchItem 찾기
                    let originalItems = self.currentState.originalSearchItems

                    if let matchingItem = originalItems.first(where: { $0.isbn == book.isbn }) {
                        // 원본 데이터를 RealmBook으로 변환
                        let realmBook = matchingItem.toRealmBook()

                        Analytics.logEvent("book_added_to_library", parameters: [
                            "book_title": realmBook.cleanTitle,
                            "book_isbn": realmBook.isbn
                        ])

                        // Realm에 저장 후 업데이트된 Book 가져오기
                        return self.saveBookWithRepository(realmBook)
                            .do(onNext: { success in
                                if success {
                                    print(" 책 저장 성공: \(realmBook.cleanTitle)")
                                    print(" 저장된 데이터:")
                                    print("  - 제목: \(realmBook.cleanTitle)")
                                    print("  - 저자: \(realmBook.author)")
                                    print("  - 출판사: \(realmBook.publisher)")
                                    print("  - 출간일: \(realmBook.pubdate)")
                                    print("  - 가격: \(realmBook.formattedPrice ?? "정보 없음")")
                                    print("  - ISBN: \(realmBook.isbn)")
                                } else {
                                    print(" 책 저장 실패: \(realmBook.cleanTitle)")
                                }
                            })
                            .flatMap { success -> Observable<Mutation> in
                                guard success else {
                                    return Observable.just(.setError(nil))
                                }
                                // 저장 후 업데이트된 Book 가져오기
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
                        print(" 매칭되는 원본 데이터를 찾을 수 없음: \(book.title)")
                        return Observable.just(.setError("원본 데이터를 찾을 수 없습니다."))
                    }
                }
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
        }

        return newState
    }

    // MARK: - Private Methods
    private func saveSearchHistory(keyword: String) -> Observable<Mutation> {
        return searchHistoryRepository.saveSearchHistory(keyword: keyword)
            .map { _ in .setError(nil) }
            .catch { error in
                print(" 검색 이력 저장 실패: \(error.localizedDescription)")
                return Observable.just(.setError(nil)) // 이력 저장 실패는 검색에 영향 없음
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
                    // 페이지네이션: 기존 결과에 추가
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
                    // 새 검색: 결과 교체
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

    // MARK: - Repository Save Helper
    private func saveBookWithRepository(_ realmBook: RealmBook) -> Observable<Bool> {
        return bookRepository.saveBook(realmBook)
            .map { _ in true }
            .catch { error in
                print(" Failed to save book: \(error.localizedDescription)")
                return Observable.just(false)
            }
    }
}
