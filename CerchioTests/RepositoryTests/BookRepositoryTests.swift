//
//  BookRepositoryTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import Testing
import Foundation
import RealmSwift
import RxSwift
@testable import Cerchio

// MARK: - Book Repository Tests

@MainActor
@Suite("BookRepository Tests", .serialized)
struct BookRepositoryTests {

    let disposeBag = DisposeBag()

    // MARK: - Setup

    init() {
        Realm.Configuration.defaultConfiguration = TestRealmProvider.createInMemoryConfiguration()
    }

    // MARK: - Basic CRUD Tests

    @Test("책 저장 및 조회")
    func saveAndGetBook() async throws {
        let repository = try BookRepository()
        let mockBook = RealmBook(
            title: "테스트 도서",
            link: "https://example.com",
            image: "https://example.com/image.jpg",
            author: "테스트 작가",
            publisher: "테스트 출판사",
            isbn: "1234567890123",
            description: "테스트 설명",
            pubdate: "20240101",
            cleanTitle: "테스트 도서",
            cleanDescription: "테스트 설명"
        )

        // When: 책 저장
        let savedBook = try await repository.saveBook(mockBook)
            .toAsync()

        // Then: 저장된 책 조회
        let fetchedBook = try await repository.getBook(by: String(describing: savedBook.id))
            .toAsync()

        #expect(fetchedBook != nil)
        #expect(fetchedBook?.title == "테스트 도서")
        #expect(fetchedBook?.isbn == "1234567890123")
    }

    @Test("ISBN으로 책 조회")
    func getBookByISBN() async throws {
        let repository = try BookRepository()
        let book = Book(
            title: "Swift 프로그래밍",
            image: "https://example.com/swift.jpg",
            author: "Apple",
            isbn: "9781234567890",
            publisher: "Apple Press"
        )

        _ = try await repository.saveBookStruct(book).toAsync()

        let fetchedBook = try await repository.getBookByISBN("9781234567890").toAsync()

        #expect(fetchedBook != nil)
        #expect(fetchedBook?.title == "Swift 프로그래밍")
        #expect(fetchedBook?.author == "Apple")
    }

    @Test("ISBN으로 책 존재 여부 확인")
    func bookExistsByISBN() async throws {
        let repository = try BookRepository()
        let book = Book(
            title: "존재하는 책",
            image: "https://example.com/book.jpg",
            author: "작가",
            isbn: "1111111111111"
        )

        _ = try await repository.saveBookStruct(book).toAsync()

        let exists = try await repository.bookExistsByISBN("1111111111111").toAsync()
        #expect(exists == true)

        let notExists = try await repository.bookExistsByISBN("9999999999999").toAsync()
        #expect(notExists == false)
    }

    @Test("책 업데이트")
    func updateBook() async throws {
        let repository = try BookRepository()
        let book = Book(
            title: "원본 제목",
            image: "https://example.com/book.jpg",
            author: "원본 작가",
            isbn: "1234567890123"
        )

        let savedBook = try await repository.saveBookStruct(book).toAsync()

        // When: 책 정보 업데이트
        let updatedBook = Book(
            id: savedBook.id,
            title: "수정된 제목",
            image: savedBook.image,
            author: "수정된 작가",
            isbn: savedBook.isbn,
            totalPages: 500,
            startDate: Date(),
            isFavorite: true
        )

        let result = try await repository.saveBookStruct(updatedBook).toAsync()

        #expect(result.title == "수정된 제목")
        #expect(result.author == "수정된 작가")
        #expect(result.totalPages == 500)
        #expect(result.isFavorite == true)
    }

    // MARK: - Favorite Tests

    @Test("즐겨찾기 토글")
    func toggleFavorite() async throws {
        let repository = try BookRepository()
        let book = Book(
            title: "즐겨찾기 테스트",
            image: "https://example.com/book.jpg",
            author: "작가",
            isbn: "1234567890123",
            isFavorite: false
        )

        let savedBook = try await repository.saveBookStruct(book).toAsync()
        #expect(savedBook.isFavorite == false)

        // When: 첫 번째 토글 (false -> true)
        let firstToggle = try await repository.toggleFavorite(bookId: savedBook.id).toAsync()
        #expect(firstToggle == true)

        // When: 두 번째 토글 (true -> false)
        let secondToggle = try await repository.toggleFavorite(bookId: savedBook.id).toAsync()
        #expect(secondToggle == false)
    }

    @Test("즐겨찾기 목록 조회")
    func getFavoriteBooks() async throws {
        let repository = try BookRepository()

        let book1 = Book(title: "Book 1", image: "img1", author: "A1", isbn: "111", isFavorite: true)
        let book2 = Book(title: "Book 2", image: "img2", author: "A2", isbn: "222", isFavorite: false)
        let book3 = Book(title: "Book 3", image: "img3", author: "A3", isbn: "333", isFavorite: true)

        _ = try await repository.saveBookStruct(book1).toAsync()
        _ = try await repository.saveBookStruct(book2).toAsync()
        _ = try await repository.saveBookStruct(book3).toAsync()

        let favorites = try await repository.getFavoriteBooks().toAsync()

        #expect(favorites.count == 2)
        #expect(favorites.allSatisfy { $0.isFavorite })
    }

    // MARK: - Delete Tests

    @Test("책 삭제")
    func deleteBookByISBN() async throws {
        let repository = try BookRepository()
        let book = Book(
            title: "삭제될 책",
            image: "https://example.com/book.jpg",
            author: "작가",
            isbn: "1234567890123"
        )

        _ = try await repository.saveBookStruct(book).toAsync()

        try await repository.deleteBookByISBN("1234567890123").toAsync()

        let deletedBook = try await repository.getBookByISBN("1234567890123").toAsync()
        #expect(deletedBook == nil)
    }

    @Test("책 삭제 시 관련 데이터 cascade 삭제")
    func deleteBookWithRelatedData() async throws {
        let realm = try await MainActor.run { try Realm() }
        let repository = try BookRepository()

        // 책 생성
        let book = Book(
            title: "관계된 데이터가 있는 책",
            image: "https://example.com/book.jpg",
            author: "작가",
            isbn: "1234567890123"
        )
        let savedBook = try await repository.saveBookStruct(book).toAsync()
        let bookId = savedBook.id

        // 관련 데이터 생성 (인용구, 사진, 태그)
        try await MainActor.run {
            try realm.write {
                let quote = RealmQuote(bookId: bookId, quote: "테스트 인용구")
                let photo = RealmPhoto(bookId: bookId, localImagePath: "/test/path.jpg")
                let tag = RealmTag(bookId: bookId, tagName: "테스트태그")

                realm.add([quote, photo, tag])
            }
        }

        // 삭제 전 확인
        let (quotesBefore, photosBefore, tagsBefore) = await MainActor.run {
            let quotes = realm.objects(RealmQuote.self).filter("bookId == %@", bookId)
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let tags = realm.objects(RealmTag.self).filter("bookId == %@", bookId)
            return (quotes.count, photos.count, tags.count)
        }

        #expect(quotesBefore == 1)
        #expect(photosBefore == 1)
        #expect(tagsBefore == 1)

        // When: 책 삭제
        try await repository.deleteBookByISBN("1234567890123").toAsync()

        // Then: 모든 관련 데이터가 삭제되었는지 확인
        let (quotesAfter, photosAfter, tagsAfter) = await MainActor.run {
            let quotes = realm.objects(RealmQuote.self).filter("bookId == %@", bookId)
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let tags = realm.objects(RealmTag.self).filter("bookId == %@", bookId)
            return (quotes.isEmpty, photos.isEmpty, tags.isEmpty)
        }

        #expect(quotesAfter)
        #expect(photosAfter)
        #expect(tagsAfter)
    }

    @Test("여러 책 동시 삭제")
    func deleteMultipleBooksByISBNs() async throws {
        let repository = try BookRepository()
        let isbns = ["111", "222", "333"]

        for (index, isbn) in isbns.enumerated() {
            let book = Book(
                title: "Book \(index)",
                image: "img\(index)",
                author: "Author \(index)",
                isbn: isbn
            )
            _ = try await repository.saveBookStruct(book).toAsync()
        }

        try await repository.deleteBooksByISBNs(isbns).toAsync()

        for isbn in isbns {
            let book = try await repository.getBookByISBN(isbn).toAsync()
            #expect(book == nil)
        }
    }

    // MARK: - Query Tests

    @Test("모든 책 조회")
    func getAllBooks() async throws {
        let repository = try BookRepository()

        for i in 0..<5 {
            let book = Book(
                title: "Book \(i)",
                image: "img\(i)",
                author: "Author \(i)",
                isbn: "ISBN\(i)"
            )
            _ = try await repository.saveBookStruct(book).toAsync()
        }

        let books = try await repository.getAllBooksAsStruct().toAsync()

        #expect(books.count == 5)
    }

    // MARK: - Edge Cases

    @Test("존재하지 않는 책 삭제 시 에러 없이 처리")
    func deleteNonExistentBook() async throws {
        let repository = try BookRepository()

        // When & Then: 에러 없이 완료되어야 함
        try await repository.deleteBookByISBN("nonexistent").toAsync()
    }

    @Test("잘못된 ISBN 형식으로 조회")
    func getBookWithInvalidISBN() async throws {
        let repository = try BookRepository()

        let book = try await repository.getBookByISBN("").toAsync()

        #expect(book == nil)
    }
}

// MARK: - Observable to Async Extension

extension Observable {
    /// Converts Observable to async/await
    func toAsync() async throws -> Element {
        return try await withCheckedThrowingContinuation { continuation in
            var disposable: Disposable?

            disposable = self
                .take(1)
                .subscribe(
                    onNext: { value in
                        continuation.resume(returning: value)
                    },
                    onError: { error in
                        continuation.resume(throwing: error)
                    },
                    onCompleted: {
                    }
                )

            _ = disposable
        }
    }
}
