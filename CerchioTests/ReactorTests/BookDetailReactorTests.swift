//
//  BookDetailReactorTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import Testing
import Foundation
import RealmSwift
import RxSwift
import ReactorKit
@testable import Cerchio

// MARK: - Book Detail Reactor Tests

@MainActor
@Suite("BookDetailReactor Tests", .serialized)
struct BookDetailReactorTests {

    let disposeBag = DisposeBag()

    // MARK: - Setup

    init() {
        Realm.Configuration.defaultConfiguration = TestRealmProvider.createInMemoryConfiguration()
    }

    // MARK: - Initial State Tests

    @Test("초기 상태 설정")
    func initialState() throws {
        // Given
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123",
            isFavorite: true
        )

        let mockRepository = MockBookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: mockRepository)

        // Then
        #expect(reactor.currentState.book.title == "테스트 도서")
        #expect(reactor.currentState.isFavorite == true)
        #expect(reactor.currentState.bookDetail == nil)
        #expect(reactor.currentState.isLoading == false)
    }

    // MARK: - Load Book Detail Tests

    @Test("책 상세 정보 로드")
    func loadBookDetail() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123",
            totalPages: 300
        )

        let realmBook = book.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // When
        reactor.action.onNext(.loadBookDetail)

        // Then: State 변화 확인
        let state = try await reactor.state
            .filter { $0.bookDetail != nil }
            .take(1)
            .toAsync()

        #expect(state.bookDetail != nil)
        #expect(state.bookDetail?.totalPages == 300)
        #expect(state.isLoading == false)
    }

    // MARK: - Favorite Toggle Tests

    @Test("즐겨찾기 토글 - false to true")
    func toggleFavoriteToTrue() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123",
            isFavorite: false
        )

        let realmBook = book.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // When
        reactor.action.onNext(.toggleFavorite)

        // Then
        let state = try await reactor.state
            .filter { $0.isFavorite == true }
            .take(1)
            .toAsync()

        #expect(state.isFavorite == true)
        #expect(state.book.isFavorite == true)
    }

    @Test("즐겨찾기 토글 - true to false")
    func toggleFavoriteToFalse() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123",
            isFavorite: true
        )

        let realmBook = book.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // When
        reactor.action.onNext(.toggleFavorite)

        // Then
        let state = try await reactor.state
            .filter { $0.isFavorite == false }
            .take(1)
            .toAsync()

        #expect(state.isFavorite == false)
    }

    // MARK: - Reading Info Update Tests

    @Test("독서 정보 업데이트")
    func updateReadingInfo() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123"
        )

        let realmBook = book.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // loadBookDetail을 먼저 호출하여 bookDetail 초기화
        reactor.action.onNext(.loadBookDetail)

        _ = try await reactor.state
            .filter { $0.bookDetail != nil }
            .take(1)
            .toAsync()

        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400 * 7)

        // When: 독서 정보 업데이트
        reactor.action.onNext(.updateReadingInfo(totalPages: 500, startDate: startDate, endDate: endDate))

        // Then
        let state = try await reactor.state
            .filter { $0.bookDetail?.totalPages == 500 }
            .take(1)
            .toAsync()

        #expect(state.bookDetail?.totalPages == 500)
        #expect(state.bookDetail?.startDate != nil)
        #expect(state.bookDetail?.endDate != nil)
        #expect(state.book.totalPages == 500)
    }

    // MARK: - Delete Book Tests

    @Test("책 삭제")
    func deleteBook() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let book = Book(
            title: "삭제될 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123"
        )

        let realmBook = book.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // When
        reactor.action.onNext(.deleteBook)

        // Then
        let state = try await reactor.state
            .filter { $0.isDeleted }
            .take(1)
            .toAsync()

        #expect(state.isDeleted == true)

        // 실제로 삭제되었는지 확인
        let deletedBook = realm.objects(RealmBook.self).filter("isbn == %@", "1234567890123")
        #expect(deletedBook.isEmpty)
    }

    // MARK: - Update Book and Reload Tests

    @Test("책 정보 업데이트 및 재로드")
    func updateBookAndReload() async throws {
        // Given
        let realm = try await MainActor.run { try Realm() }
        let originalBook = Book(
            title: "원본 제목",
            image: "https://example.com/image.jpg",
            author: "원본 작가",
            isbn: "1234567890123"
        )

        let realmBook = originalBook.toRealmBook()
        try await MainActor.run {
            try realm.write {
                realm.add(realmBook)
            }
        }

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: originalBook, bookRepository: repository)

        // When: 책 정보 업데이트
        let updatedBook = Book(
            id: originalBook.id,
            title: "수정된 제목",
            image: originalBook.image,
            author: "수정된 작가",
            isbn: originalBook.isbn
        )

        reactor.action.onNext(.updateBookAndReload(updatedBook))

        // Then
        let state = try await reactor.state
            .filter { $0.book.title == "수정된 제목" }
            .take(1)
            .toAsync()

        #expect(state.book.title == "수정된 제목")
        #expect(state.book.author == "수정된 작가")
        #expect(state.bookDetail != nil)
    }

    // MARK: - State Mutation Tests

    @Test("Loading 상태 변화")
    func loadingStateChanges() async throws {
        // Given
        let book = Book(
            title: "테스트 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "1234567890123"
        )

        let mockRepository = MockBookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: mockRepository)

        // When: loadBookDetail 액션 실행
        reactor.action.onNext(.loadBookDetail)

        // Then: loading 상태가 변경되는지 확인
        let finalState = try await reactor.state
            .skip(1) // 초기 상태 스킵
            .take(1)
            .toAsync()

        // 최종적으로 loading이 false가 되어야 함
        #expect(finalState.isLoading == false)
    }

    // MARK: - Error Handling Tests

    @Test("존재하지 않는 책 조회 시 에러 처리")
    func handleNonExistentBook() async throws {
        // Given: Realm에 저장되지 않은 책
        let book = Book(
            title: "존재하지 않는 도서",
            image: "https://example.com/image.jpg",
            author: "작가",
            isbn: "9999999999999"
        )

        let repository = try BookRepository()
        let reactor = BookDetailReactor(book: book, bookRepository: repository)

        // When
        reactor.action.onNext(.loadBookDetail)

        // Then: BookDetail은 기본 Book 정보로 생성되어야 함
        let state = try await reactor.state
            .filter { $0.bookDetail != nil }
            .take(1)
            .toAsync()

        #expect(state.bookDetail != nil)
        #expect(state.bookDetail?.book.title == "존재하지 않는 도서")
    }
}

// MARK: - Mock Book Repository

final class MockBookRepository: BookRepositoryProtocol {

    var books: [Book] = []
    var shouldFailNextOperation = false

    func getAllBooks() -> Observable<[RealmBook]> {
        return Observable.just([])
    }

    func getBook(by id: String) -> Observable<RealmBook?> {
        return Observable.just(nil)
    }

    func saveBook(_ book: RealmBook) -> Observable<RealmBook> {
        return Observable.just(book)
    }

    func deleteBook(_ book: RealmBook) -> Observable<Void> {
        return Observable.just(())
    }

    func deleteBooksWithRelatedData(_ books: [RealmBook]) -> Observable<Void> {
        return Observable.just(())
    }

    func deleteBooksByIds(_ bookIds: [ObjectId]) -> Observable<Void> {
        return Observable.just(())
    }

    func getAllBooksAsStruct() -> Observable<[Book]> {
        return Observable.just(books)
    }

    func getBookByISBN(_ isbn: String) -> Observable<Book?> {
        let book = books.first { $0.isbn == isbn }
        return Observable.just(book)
    }

    func bookExistsByISBN(_ isbn: String) -> Observable<Bool> {
        return Observable.just(books.contains { $0.isbn == isbn })
    }

    func saveBookStruct(_ book: Book) -> Observable<Book> {
        if shouldFailNextOperation {
            return Observable.error(TestError.dataNotFound)
        }

        books.append(book)
        return Observable.just(book)
    }

    func deleteBookByISBN(_ isbn: String) -> Observable<Void> {
        books.removeAll { $0.isbn == isbn }
        return Observable.just(())
    }

    func deleteBooksByISBNs(_ isbns: [String]) -> Observable<Void> {
        books.removeAll { isbns.contains($0.isbn) }
        return Observable.just(())
    }

    func toggleFavorite(bookId: String) -> Observable<Bool> {
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            let newFavoriteState = !books[index].isFavorite
            books[index] = Book(
                id: books[index].id,
                title: books[index].title,
                image: books[index].image,
                author: books[index].author,
                isbn: books[index].isbn,
                isFavorite: newFavoriteState
            )
            return Observable.just(newFavoriteState)
        }
        return Observable.just(false)
    }

    func getFavoriteBooks() -> Observable<[Book]> {
        return Observable.just(books.filter { $0.isFavorite })
    }

    func deleteAllData() -> Observable<Void> {
        books.removeAll()
        return Observable.just(())
    }
}
