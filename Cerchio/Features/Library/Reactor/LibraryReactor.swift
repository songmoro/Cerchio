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
        case applyTagFilters([String])
        case clearFilters
    }

    enum Mutation {
        case setBooks([Book])
        case setFilteredBooks([Book])
        case setActiveFilters([String])
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var books: [Book]? = nil
        var filteredBooks: [Book]? = nil
        var activeFilters: [String] = []
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

        case .applyTagFilters(let tagNames):
            guard !tagNames.isEmpty else {
                return Observable.just(.setFilteredBooks([]))
            }

            return Observable.concat([
                Observable.just(.setLoading(true)),
                filterBooksByTags(tagNames),
                Observable.just(.setActiveFilters(tagNames)),
                Observable.just(.setLoading(false))
            ])

        case .clearFilters:
            return Observable.concat([
                Observable.just(.setFilteredBooks([])),
                Observable.just(.setActiveFilters([]))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setBooks(let books):
            newState.books = books

        case .setFilteredBooks(let books):
            newState.filteredBooks = books.isEmpty ? nil : books

        case .setActiveFilters(let filters):
            newState.activeFilters = filters

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

    private func filterBooksByTags(_ tagNames: [String]) -> Observable<Mutation> {
        return tagRepository.getAllTags()
            .map { [weak self] allTags -> [Book] in
                guard let self = self,
                      let allBooks = self.currentState.books else { return [] }

                // 선택된 태그에 해당하는 bookId 추출
                let filteredTags = allTags.filter { tagNames.contains($0.tagName) }
                let bookIds = Set(filteredTags.map { $0.bookId })

                // bookId가 일치하는 책들 필터링
                return allBooks.filter { book in
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
