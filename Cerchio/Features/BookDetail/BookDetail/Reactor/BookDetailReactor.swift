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
        case updateReadingInfo(totalPages: Int, startDate: Date?, endDate: Date?)
        case toggleFavorite
        case addQuote(String)
        case deleteBook
        case updateBookAndReload(Book)
    }

    enum Mutation {
        case setBookDetail(BookDetail)
        case setLoading(Bool)
        case setError(Error?)
        case setFavorite(Bool)
        case setReadingProgress(ReadingProgress)
        case updateBook(Book)
        case bookDeleted
    }

    struct State {
        var book: Book
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
        var isFavorite: Bool = false
        var readingProgress: ReadingProgress?
        var isDeleted: Bool = false
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
            // 최신 Book 데이터를 먼저 로드하여 isFavorite 등의 상태를 동기화
            return Observable.concat([
                Observable.just(.setLoading(true)),
                bookRepository.getBookByISBN(currentState.book.isbn)
                    .flatMap { [weak self] updatedBook -> Observable<Mutation> in
                        guard let self = self else { return Observable.empty() }

                        if let updatedBook = updatedBook {
                            // Book이 업데이트되었으면 먼저 Book을 업데이트
                            return Observable.concat([
                                Observable.just(.updateBook(updatedBook)),
                                self.loadBookDetailDataWithBook(updatedBook)
                            ])
                        } else {
                            // Book을 찾지 못했으면 기존 Book으로 로드
                            return self.loadBookDetailData()
                        }
                    }
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

        case .updateReadingInfo(let totalPages, let startDate, let endDate):
            // BookDetail 업데이트
            guard var bookDetail = currentState.bookDetail else {
                print("❌ No bookDetail in currentState")
                return Observable.empty()
            }

            print("📖 Updating reading info - totalPages: \(totalPages), startDate: \(String(describing: startDate)), endDate: \(String(describing: endDate))")

            let updatedBookDetail = BookDetail(
                book: bookDetail.book,
                totalPages: totalPages,
                startDate: startDate,
                endDate: endDate,
                tags: bookDetail.tags
            )

            // Realm에 저장
            return bookRepository.getBookByISBN(currentState.book.isbn)
                .flatMap { [weak self] existingBook -> Observable<Mutation> in
                    guard let self = self, var existingBook = existingBook else {
                        print("❌ No existing book found for ISBN: \(self?.currentState.book.isbn ?? "unknown")")
                        return Observable.empty()
                    }

                    print("📖 Found existing book - current startDate: \(String(describing: existingBook.startDate))")

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
                        endDate: endDate,
                        isFavorite: existingBook.isFavorite,
                        dateAdded: existingBook.dateAdded,
                        dateRead: existingBook.dateRead,
                        readingStatus: existingBook.readingStatus,
                        category: existingBook.category,
                        rating: existingBook.rating
                    )

                    print("📖 Created updatedBook - startDate: \(String(describing: updatedBook.startDate))")

                    return self.bookRepository.saveBookStruct(updatedBook)
                        .flatMap { savedBook -> Observable<Mutation> in
                            print("✅ Book saved - startDate: \(String(describing: savedBook.startDate))")
                            return Observable.concat([
                                Observable.just(.updateBook(savedBook)),
                                Observable.just(.setBookDetail(updatedBookDetail))
                            ])
                        }
                        .catch { error in
                            print("❌ Failed to update reading info: \(error.localizedDescription)")
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
            return bookRepository.deleteBookByISBN(currentState.book.isbn)
                .map { _ in .bookDeleted }
                .catch { error in
                    print("❌ Failed to delete book: \(error.localizedDescription)")
                    return Observable.just(.setError(error))
                }

        case .updateBookAndReload(let updatedBook):
            // Book 업데이트 후 BookDetail 다시 로드
            return Observable.concat([
                Observable.just(.updateBook(updatedBook)),
                Observable.just(.setLoading(true)),
                loadBookDetailDataWithBook(updatedBook),
                Observable.just(.setLoading(false))
            ])
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
            // Book이 업데이트되면 isFavorite 상태도 함께 업데이트
            newState.isFavorite = book.isFavorite

        case .bookDeleted:
            newState.isDeleted = true
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
            endDate: currentState.book.endDate,
            tags: [] // 실제 태그는 Realm에서 로드
        )

        return Observable.just(.setBookDetail(bookDetail))
    }

    private func loadBookDetailDataWithBook(_ book: Book) -> Observable<Mutation> {
        // 업데이트된 Book으로 BookDetail 생성
        let bookDetail = BookDetail(
            book: book,
            totalPages: book.totalPages ?? 0,
            startDate: book.startDate,
            endDate: book.endDate,
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
