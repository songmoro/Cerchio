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
            // 현재 상태에서 매칭되는 원본 BookSearchItem 찾기
            let originalItems = currentState.originalSearchItems

            if let matchingItem = originalItems.first(where: { $0.isbn == book.isbn }) {
                // 원본 데이터를 RealmBook으로 변환
                let realmBook = matchingItem.toRealmBook()

                // Realm에 저장
                return saveBookToRealm(realmBook)
                    .do(onNext: { success in
                        if success {
                            print("✅ 책 저장 성공: \(realmBook.cleanTitle)")
                            print("📚 저장된 데이터:")
                            print("  - 제목: \(realmBook.cleanTitle)")
                            print("  - 저자: \(realmBook.author)")
                            print("  - 출판사: \(realmBook.publisher)")
                            print("  - 출간일: \(realmBook.pubdate)")
                            print("  - 가격: \(realmBook.formattedPrice ?? "정보 없음")")
                            print("  - ISBN: \(realmBook.isbn)")
                        } else {
                            print("❌ 책 저장 실패: \(realmBook.cleanTitle)")
                        }
                    })
                    .map { _ in .setError(nil) }
            } else {
                print("⚠️ 매칭되는 원본 데이터를 찾을 수 없음: \(book.title)")
                return Observable.just(.setError("원본 데이터를 찾을 수 없습니다."))
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

    // MARK: - Realm Save Helper
    private func saveBookToRealm(_ realmBook: RealmBook) -> Observable<Bool> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                print(realm.configuration.fileURL)
                try realm.write {
                    realm.add(realmBook)
                }
                observer.onNext(true)
                observer.onCompleted()
            } catch {
                print("❌ Realm 저장 에러: \(error.localizedDescription)")
                observer.onNext(false)
                observer.onCompleted()
            }
            return Disposables.create()
        }
//        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .observe(on: MainScheduler.instance)
    }
}
