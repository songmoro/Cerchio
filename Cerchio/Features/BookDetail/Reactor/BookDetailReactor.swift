//
//  BookDetailReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import ReactorKit
import RxSwift

final class BookDetailReactor: Reactor {
    enum Action {
        case loadBookDetail
        case updateReadingProgress(currentPage: Int)
        case toggleFavorite
        case addQuote(String)
        case deleteBook
    }

    enum Mutation {
        case setBookDetail(BookDetail)
        case setLoading(Bool)
        case setError(Error?)
        case setFavorite(Bool)
        case setReadingProgress(ReadingProgress)
        case addQuoteToList(Quote)
    }

    struct State {
        var book: Book
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
        var isFavorite: Bool = false
        var readingProgress: ReadingProgress?
        var quotes: [Quote] = []
    }

    let initialState: State

    // MARK: - Initialization
    init(book: Book) {
        self.initialState = State(book: book)
    }

    // MARK: - Reactor Methods
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadBookDetail:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadBookDetailData()
                    .delay(.milliseconds(300), scheduler: MainScheduler.instance),
                Observable.just(.setLoading(false))
            ])

        case .updateReadingProgress(let currentPage):
//            let progress = ReadingProgress(
//                bookId: currentState.book.id.stringValue,
//                currentPage: currentPage,
//                totalPages: currentState.bookDetail?.totalPages ?? 0,
//                startDate: currentState.readingProgress?.startDate
//            )
//            return Observable.just(.setReadingProgress(progress))
            return .empty()
        case .toggleFavorite:
            let newFavoriteStatus = !currentState.isFavorite
            return Observable.just(.setFavorite(newFavoriteStatus))

        case .addQuote(let text):
            let newQuote = Quote(
                text: text,
                pageNumber: currentState.readingProgress?.currentPage ?? 0,
                createdDate: Date()
            )
            return Observable.just(.addQuoteToList(newQuote))

        case .deleteBook:
            // TODO: 실제 삭제 로직 구현
            return Observable.empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setBookDetail(let bookDetail):
            newState.bookDetail = bookDetail

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error

        case .setFavorite(let isFavorite):
            newState.isFavorite = isFavorite

        case .setReadingProgress(let progress):
            newState.readingProgress = progress

        case .addQuoteToList(let quote):
            newState.quotes.append(quote)
        }

        return newState
    }

    // MARK: - Private Methods
    private func loadBookDetailData() -> Observable<Mutation> {
        // RealmBook을 기반으로 BookDetail 생성
        let bookDetail = BookDetail(
            book: currentState.book,
            totalPages: 320, // 기본값 (RealmBook에 totalPages 정보 없음)
            startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            endDate: nil,
            tags: ["소설", "클래식", "필독서"] // 기본값 (RealmBook에 태그 정보 없음)
        )

        return Observable.just(.setBookDetail(bookDetail))
    }
}

// MARK: - Supporting Models
struct BookDetail: Hashable {
    let book: Book
    let totalPages: Int
    let startDate: Date?
    let endDate: Date?
    let tags: [String]
}


struct Quote: Hashable {
    let text: String
    let pageNumber: Int
    let createdDate: Date
}
