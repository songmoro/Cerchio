//
//  BookDetailReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import UIKit
import ReactorKit
import RxSwift
import RealmSwift
import FirebaseAnalytics

final class BookDetailReactor: Reactor {
    enum Action {
        case loadBookDetail
        case updateReadingProgress(currentPage: Int)
        case updateReadingInfo(totalPages: Int, startDate: Date?, endDate: Date?)
        case toggleFavorite
        case addQuote(String)
        case deleteBook
        case updateBookAndReload(Book)
        case loadReadingStatistics

        // Photo actions
        case loadPhotos
        case savePhoto(UIImage)
        case deletePhoto(String)

        // Tag actions
        case loadTags
        case saveTags([String])

        // Quote actions
        case loadQuotes
        case deleteQuote(String, Date)
    }

    enum Mutation {
        case setBookDetail(BookDetail)
        case clearBookDetail
        case setLoading(Bool)
        case setError(Error?)
        case setFavorite(Bool)
        case setReadingProgress(ReadingProgress)
        case updateBook(Book)
        case bookDeleted
        case setReadingStatistics(ReadingStatistics)

        // Data loading
        case setPhotos([PhotoItem])
        case setQuotes([RealmQuote])
        case setTags([RealmTag])

        // Data change notifications
        case photoSaved
        case photoDeleted
        case tagsSaved
    }

    struct PhotoItem: Hashable, Sendable {
        let id: String
        let image: UIImage

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
            return lhs.id == rhs.id
        }
    }

    struct State {
        var book: Book
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
        var isFavorite: Bool = false
        var readingProgress: ReadingProgress?
        var isDeleted: Bool = false
        var readingStatistics: ReadingStatistics?

        // Data
        var photos: [PhotoItem] = []
        var quotes: [RealmQuote] = []
        var tags: [RealmTag] = []

        // Data change flags for UI refresh
        var shouldRefreshPhotos: Bool = false
        var shouldRefreshTags: Bool = false
    }

    let initialState: State
    private let bookRepository: BookRepositoryProtocol
    private let service: BookDetailService

    // MARK: - Initialization
    init(book: Book, bookRepository: BookRepositoryProtocol, service: BookDetailService) {
        self.initialState = State(book: book, isFavorite: book.isFavorite)
        self.bookRepository = bookRepository
        self.service = service
    }

    // MARK: - Reactor Methods
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadBookDetail:
            // 최신 Book 데이터를 먼저 로드하여 isFavorite 등의 상태를 동기화
            return bookRepository.getBookByISBN(currentState.book.isbn)
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

//        case .updateReadingProgress(let currentPage):
        case .updateReadingProgress(_):
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
            guard let bookDetail = currentState.bookDetail else {
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
                    guard let self = self, let existingBook = existingBook else {
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

                    Analytics.logEvent("book_favorite_toggled", parameters: [
                        "book_title": self.currentState.book.cleanTitle,
                        "is_favorite": isFavorite
                    ])

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
            Analytics.logEvent("book_deleted", parameters: [
                "book_title": currentState.book.cleanTitle
            ])

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

        case .loadReadingStatistics:
            return service.calculateReadingStatistics(for: currentState.book.id)
                .map { Mutation.setReadingStatistics($0) }
                .catch { error in
                    print("❌ Failed to load reading statistics: \(error)")
                    return Observable.empty()
                }

        case .loadPhotos:
            let bookId = String(describing: currentState.book.id)
            return service.loadPhotos(bookId: bookId)
                .observe(on: MainScheduler.instance)
                .flatMap { photos -> Observable<Mutation> in
                    let photoData = photos.sorted { $0.createdAt > $1.createdAt }
                        .map { (id: String(describing: $0.id), path: $0.localImagePath) }

                    return Observable.create { observer in
                        Task {
                            var photoItems: [PhotoItem] = []
                            for data in photoData {
                                if let image = ImageStorageManager.shared.loadImage(fromPath: data.path) {
                                    photoItems.append(PhotoItem(id: data.id, image: image))
                                }
                            }
                            await MainActor.run {
                                observer.onNext(.setPhotos(photoItems))
                                observer.onCompleted()
                            }
                        }
                        return Disposables.create()
                    }
                }
                .catch { error in
                    print("❌ Failed to load photos: \(error)")
                    return Observable.empty()
                }

        case .loadQuotes:
            let bookId = String(describing: currentState.book.id)
            return service.loadQuotes(bookId: bookId)
                .observe(on: MainScheduler.instance)
                .map { Mutation.setQuotes($0) }
                .catch { error in
                    print("❌ Failed to load quotes: \(error)")
                    return Observable.empty()
                }

        case .loadTags:
            let bookId = String(describing: currentState.book.id)
            return service.loadTags(bookId: bookId)
                .observe(on: MainScheduler.instance)
                .map { Mutation.setTags($0) }
                .catch { error in
                    print("❌ Failed to load tags: \(error)")
                    return Observable.empty()
                }

        case .savePhoto(let image):
            let bookId = String(describing: currentState.book.id)
            return service.savePhoto(image, bookId: bookId)
                .map { _ in Mutation.photoSaved }
                .catch { error in
                    print("❌ Failed to save photo: \(error)")
                    return Observable.just(Mutation.setError(error))
                }

        case .deletePhoto(let photoId):
            guard let objectId = try? ObjectId(string: photoId),
                  let realm = try? Realm(),
                  let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: objectId) else {
                print("❌ Photo not found")
                return Observable.empty()
            }

            // Delete local file
            _ = ImageStorageManager.shared.deleteImage(atPath: photo.localImagePath)

            // Delete from repository
            let photoRepository = service.serviceFactory.createPhotoRepository()
            return photoRepository.deletePhoto(photo)
                .map { _ in Mutation.photoDeleted }
                .catch { error in
                    print("❌ Failed to delete photo: \(error)")
                    return Observable.just(Mutation.setError(error))
                }

        case .saveTags(let tags):
            let bookId = String(describing: currentState.book.id)
            let tagRepository = service.serviceFactory.createTagRepository()

            // Delete existing tags, then save new ones
            return tagRepository.deleteTags(for: bookId)
                .flatMap { _ -> Observable<Mutation> in
                    guard !tags.isEmpty else {
                        return Observable.just(Mutation.tagsSaved)
                    }

                    let realmTags = tags.map { RealmTag(bookId: bookId, tagName: $0) }
                    return tagRepository.saveTags(realmTags)
                        .map { _ in Mutation.tagsSaved }
                }
                .catch { error in
                    print("❌ Failed to save tags: \(error)")
                    return Observable.just(Mutation.setError(error))
                }

        case .deleteQuote(let quote, let date):
            let bookId = String(describing: currentState.book.id)
            let quoteRepository = service.serviceFactory.createQuoteRepository()

            return quoteRepository.getQuotes(for: bookId)
                .take(1)
                .flatMap { quotes -> Observable<Mutation> in
                    let quotesArray = Array(quotes)
                    guard let quoteToDelete = quotesArray.first(where: { $0.quote == quote && $0.createdAt == date }) else {
                        print("❌ Quote not found")
                        return Observable.empty()
                    }

                    return quoteRepository.deleteQuote(quoteToDelete)
                        .flatMap { _ -> Observable<Mutation> in
                            // 삭제 후 즉시 최신 데이터 로드
                            return self.service.loadQuotes(bookId: bookId)
                                .observe(on: MainScheduler.instance)
                                .map { Mutation.setQuotes($0) }
                        }
                }
                .catch { error in
                    print("❌ Failed to delete quote: \(error)")
                    return Observable.just(Mutation.setError(error))
                }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        // Reset refresh flags
        newState.shouldRefreshPhotos = false
        newState.shouldRefreshTags = false

        switch mutation {
        case .setBookDetail(let bookDetail):
            newState.bookDetail = bookDetail

        case .clearBookDetail:
            // BookDetail을 초기화하여 UI가 변경을 감지하도록 함
            newState.bookDetail = nil

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

        case .setReadingStatistics(let statistics):
            newState.readingStatistics = statistics

        case .setPhotos(let photos):
            newState.photos = photos

        case .setQuotes(let quotes):
            newState.quotes = quotes

        case .setTags(let tags):
            newState.tags = tags

        case .photoSaved, .photoDeleted:
            newState.shouldRefreshPhotos = true

        case .tagsSaved:
            newState.shouldRefreshTags = true
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
nonisolated struct BookDetail: Hashable, Sendable {
    let book: Book
    let totalPages: Int
    let startDate: Date?
    let endDate: Date?
    let tags: [String]
}
