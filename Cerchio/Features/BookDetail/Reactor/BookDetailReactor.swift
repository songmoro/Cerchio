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
        case updateReadingInfo(totalPages: Int, startDate: Date?)
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
        case updateBook(Book)
    }

    struct State {
        var book: Book
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
        var isFavorite: Bool = false
        var readingProgress: ReadingProgress?
    }

    let initialState: State
    private let bookRepository: BookRepositoryProtocol

    // MARK: - Initialization
    init(book: Book, bookRepository: BookRepositoryProtocol) {
        self.initialState = State(book: book, isFavorite: book.isFavorite)
        self.bookRepository = bookRepository
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

        case .updateReadingInfo(let totalPages, let startDate):
            // BookDetail 업데이트
            guard var bookDetail = currentState.bookDetail else {
                return Observable.empty()
            }

            let updatedBookDetail = BookDetail(
                book: bookDetail.book,
                totalPages: totalPages,
                startDate: startDate,
                endDate: bookDetail.endDate,
                tags: bookDetail.tags
            )

            // Realm에 저장
            return bookRepository.getBookByISBN(currentState.book.isbn)
                .flatMap { [weak self] existingBook -> Observable<Mutation> in
                    guard let self = self, var existingBook = existingBook else {
                        return Observable.empty()
                    }

                    // Book 업데이트
                    let updatedBook = Book(
                        id: existingBook.id,
                        title: existingBook.title,
                        cleanTitle: existingBook.cleanTitle,
                        link: existingBook.link,
                        image: existingBook.image,
                        author: existingBook.author,
                        isbn: existingBook.isbn,
                        publisher: existingBook.publisher,
                        bookDescription: existingBook.bookDescription,
                        cleanDescription: existingBook.cleanDescription,
                        pubdate: existingBook.pubdate,
                        discount: existingBook.discount,
                        formattedPubDate: existingBook.formattedPubDate,
                        formattedPrice: existingBook.formattedPrice,
                        priceAsInt: existingBook.priceAsInt,
                        createAt: existingBook.createAt,
                        genre: existingBook.genre,
                        totalPages: totalPages,
                        startDate: startDate,
                        isFavorite: existingBook.isFavorite,
                        dateAdded: existingBook.dateAdded,
                        dateRead: existingBook.dateRead,
                        readingStatus: existingBook.readingStatus,
                        category: existingBook.category,
                        rating: existingBook.rating
                    )

                    return self.bookRepository.saveBookStruct(updatedBook)
                        .flatMap { savedBook -> Observable<Mutation> in
                            return Observable.concat([
                                Observable.just(.updateBook(savedBook)),
                                Observable.just(.setBookDetail(updatedBookDetail))
                            ])
                        }
                        .catch { error in
                            print("Failed to update reading info: \(error.localizedDescription)")
                            return Observable.empty()
                        }
                }

        case .toggleFavorite:
            return bookRepository.toggleFavorite(bookId: currentState.book.id)
                .flatMap { [weak self] isFavorite -> Observable<Mutation> in
                    guard let self = self else { return Observable.empty() }

                    // 업데이트된 Book을 다시 가져오기
                    return self.bookRepository.getBookByISBN(self.currentState.book.isbn)
                        .flatMap { updatedBook -> Observable<Mutation> in
                            if let updatedBook = updatedBook {
                                return Observable.concat([
                                    Observable.just(.updateBook(updatedBook)),
                                    Observable.just(.setFavorite(isFavorite))
                                ])
                            } else {
                                return Observable.just(.setFavorite(isFavorite))
                            }
                        }
                }
                .catch { error in
                    print("Failed to toggle favorite: \(error.localizedDescription)")
                    return Observable.just(.setFavorite(self.currentState.isFavorite))
                }

        case .addQuote:
            // TODO: 문장 추가 로직 구현 (현재 사용하지 않음)
            return Observable.empty()

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

        case .updateBook(let book):
            newState.book = book
        }

        return newState
    }

    // MARK: - Private Methods
    private func loadBookDetailData() -> Observable<Mutation> {
        // RealmBook을 기반으로 BookDetail 생성
        let bookDetail = BookDetail(
            book: currentState.book,
            totalPages: currentState.book.totalPages ?? 0,
            startDate: currentState.book.startDate,
            endDate: nil,
            tags: [] // 실제 태그는 Realm에서 로드
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
