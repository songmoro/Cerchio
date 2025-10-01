//
//  LibraryReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import Foundation
import RealmSwift
import ReactorKit
import RxSwift

final class LibraryReactor: Reactor {
    enum Action {
        case loadBooks
        case refreshBooks
        case applyTagFilters([String], favoriteOnly: Bool)
        case clearFilters
    }

    enum Mutation {
        case setBooks([Book])
        case setFilteredBooks([Book])
        case clearFilteredBooks
        case setActiveFilters([String])
        case setFavoriteFilter(Bool)
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var books: [Book]? = nil
        var filteredBooks: [Book]? = nil
        var activeFilters: [String] = []
        var isFavoriteFilterEnabled: Bool = false
        var isLoading: Bool = false
        var error: Error?

        var displayBooks: [Book]? {
            return filteredBooks ?? books
        }
    }

    let initialState = State()
    private let bookRepository: BookRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol

    init(bookRepository: BookRepositoryProtocol, tagRepository: TagRepositoryProtocol) {
        self.bookRepository = bookRepository
        self.tagRepository = tagRepository
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadBooks:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadBooks(),
                Observable.just(.setLoading(false))
            ])

        case .refreshBooks:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadBooks(),
                Observable.just(.setLoading(false))
            ])

        case .applyTagFilters(let tagNames, let favoriteOnly):
            return Observable.concat([
                Observable.just(.setLoading(true)),
                filterBooks(byTags: tagNames, favoriteOnly: favoriteOnly),
                Observable.just(.setActiveFilters(tagNames)),
                Observable.just(.setFavoriteFilter(favoriteOnly)),
                Observable.just(.setLoading(false))
            ])

        case .clearFilters:
            return Observable.concat([
                Observable.just(.setFilteredBooks([])),
                Observable.just(.setActiveFilters([])),
                Observable.just(.setFavoriteFilter(false)),
                Observable.just(.clearFilteredBooks)
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setBooks(let books):
            newState.books = books

        case .setFilteredBooks(let books):
            // 빈 배열도 유효한 필터 결과로 처리 (필터 적용했지만 결과가 없는 경우)
            newState.filteredBooks = books

        case .clearFilteredBooks:
            // 필터를 완전히 제거하여 모든 책 표시
            newState.filteredBooks = nil

        case .setActiveFilters(let filters):
            newState.activeFilters = filters

        case .setFavoriteFilter(let isEnabled):
            newState.isFavoriteFilterEnabled = isEnabled

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error
        }

        return newState
    }

    private func loadBooks() -> Observable<Mutation> {
        return bookRepository.getAllBooksAsStruct()
            .map { .setBooks($0) }
            .catch { error in
                print("Failed to load books: \(error.localizedDescription)")
                return Observable.just(.setError(error))
            }
    }

    private func filterBooks(byTags tagNames: [String], favoriteOnly: Bool) -> Observable<Mutation> {
        guard let allBooks = currentState.books else {
            return Observable.just(.setFilteredBooks([]))
        }

        // 즐겨찾기 필터만 활성화된 경우
        if tagNames.isEmpty && favoriteOnly {
            let favoriteBooks = allBooks.filter { $0.isFavorite }
            return Observable.just(.setFilteredBooks(favoriteBooks))
        }

        // 태그 필터만 활성화된 경우
        if !tagNames.isEmpty && !favoriteOnly {
            return filterByTags(tagNames, books: allBooks)
        }

        // 둘 다 활성화된 경우
        if !tagNames.isEmpty && favoriteOnly {
            return tagRepository.getAllTags()
                .map { [weak self] allTags -> [Book] in
                    guard let self = self else { return [] }

                    // 선택된 태그에 해당하는 bookId 추출
                    let filteredTags = allTags.filter { tagNames.contains($0.tagName) }
                    let bookIds = Set(filteredTags.map { $0.bookId })

                    // bookId가 일치하고 즐겨찾기인 책들만 필터링
                    return allBooks.filter { book in
                        bookIds.contains(String(describing: book.id)) && book.isFavorite
                    }
                }
                .map { .setFilteredBooks($0) }
                .catch { error in
                    print("Failed to filter books by tags and favorite: \(error.localizedDescription)")
                    return Observable.just(.setError(error))
                }
        }

        // 필터가 없는 경우
        return Observable.just(.setFilteredBooks([]))
    }

    private func filterByTags(_ tagNames: [String], books: [Book]) -> Observable<Mutation> {
        return tagRepository.getAllTags()
            .map { allTags -> [Book] in
                // 선택된 태그에 해당하는 bookId 추출
                let filteredTags = allTags.filter { tagNames.contains($0.tagName) }
                let bookIds = Set(filteredTags.map { $0.bookId })

                // bookId가 일치하는 책들 필터링
                return books.filter { book in
                    bookIds.contains(String(describing: book.id))
                }
            }
            .map { .setFilteredBooks($0) }
            .catch { error in
                print("Failed to filter books by tags: \(error.localizedDescription)")
                return Observable.just(.setError(error))
            }
    }
}
