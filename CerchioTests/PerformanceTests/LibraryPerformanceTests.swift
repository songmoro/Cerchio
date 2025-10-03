//
//  LibraryPerformanceTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import XCTest
import RealmSwift
import RxSwift
import ReactorKit
@testable import Cerchio

// MARK: - Library Performance Tests

final class LibraryPerformanceTests: XCTestCase {

    var realm: Realm!
    var bookRepository: BookRepository!
    var tagRepository: TagRepository!
    let disposeBag = DisposeBag()

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // In-memory Realm 설정
        var config = Realm.Configuration()
        config.inMemoryIdentifier = "test-\(UUID().uuidString)"
        Realm.Configuration.defaultConfiguration = config

        do {
            realm = try Realm(configuration: config)
            bookRepository = try BookRepository()
            tagRepository = try TagRepository()
        } catch {
            XCTFail("Failed to setup Realm: \(error)")
        }
    }

    override func tearDown() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Failed to clear test data: \(error)")
        }

        realm = nil
        bookRepository = nil
        tagRepository = nil

        super.tearDown()
    }

    // MARK: - Large Dataset Loading Performance

    func testPerformance_Loading100Books() throws {
        // Given: 100권의 책 생성
        let books = createMockBooks(count: 100)
        try realm.write {
            realm.add(books)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),           // 실행 시간
            XCTCPUMetric(),             // CPU 사용량
            XCTMemoryMetric()           // 메모리 사용량
        ]

        let options = XCTMeasureOptions()
        options.iterationCount = 5

        // When & Then: 성능 측정
        measure(metrics: metrics, options: options) {
            let expectation = expectation(description: "Load books")

            _ = bookRepository.getAllBooksAsStruct()
                .subscribe(onNext: { books in
                    XCTAssertEqual(books.count, 100)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_Loading1000Books() throws {
        // Given: 1000권의 책 생성
        let books = createMockBooks(count: 1000)
        try realm.write {
            realm.add(books)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]

        // When & Then
        measure(metrics: metrics) {
            let expectation = expectation(description: "Load 1000 books")

            _ = bookRepository.getAllBooksAsStruct()
                .subscribe(onNext: { books in
                    XCTAssertEqual(books.count, 1000)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 10.0)
        }

        // Baseline 기준: 1000권 로딩은 1초 이내여야 함
    }

    // MARK: - Tag Filtering Performance

    func testPerformance_FilteringBooksWithMultipleTags() throws {
        // Given: 500권의 책 + 각 책당 5개의 태그
        let books = createMockBooks(count: 500)
        let tags = createMockTags(for: books, tagsPerBook: 5)

        try realm.write {
            realm.add(books)
            realm.add(tags)
        }

        let reactor = LibraryReactor(
            bookRepository: bookRepository,
            tagRepository: tagRepository
        )

        // 먼저 책 로딩
        let loadExpectation = expectation(description: "Load books first")
        _ = reactor.action.onNext(.loadBooks)

        _ = reactor.state
            .map { $0.books }
            .filter { $0 != nil }
            .take(1)
            .subscribe(onNext: { _ in
                loadExpectation.fulfill()
            })

        wait(for: [loadExpectation], timeout: 5.0)

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]

        // When: 3개의 태그로 필터링
        measure(metrics: metrics) {
            let expectation = expectation(description: "Filter books")

            _ = reactor.action.onNext(.applyTagFilters(["소설", "추리", "베스트셀러"], favoriteOnly: false))

            _ = reactor.state
                .map { $0.filteredBooks }
                .filter { $0 != nil }
                .take(1)
                .subscribe(onNext: { _ in
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 5.0)
        }

        // Baseline 기준: 500권 + 2500개 태그 필터링은 1초 이내
    }

    func testPerformance_FilteringWithFavoriteAndTags() throws {
        // Given: 300권의 책 (일부 즐겨찾기) + 태그
        let books = createMockBooks(count: 300) // isFavorite는 3의 배수마다 true
        let tags = createMockTags(for: books, tagsPerBook: 3)

        try realm.write {
            realm.add(books)
            realm.add(tags)
        }

        let reactor = LibraryReactor(
            bookRepository: bookRepository,
            tagRepository: tagRepository
        )

        // 먼저 책 로딩
        let loadExpectation = expectation(description: "Load books first")
        _ = reactor.action.onNext(.loadBooks)

        _ = reactor.state
            .map { $0.books }
            .filter { $0 != nil }
            .take(1)
            .subscribe(onNext: { _ in
                loadExpectation.fulfill()
            })

        wait(for: [loadExpectation], timeout: 5.0)

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        // When: 태그 + 즐겨찾기 복합 필터링
        measure(metrics: metrics) {
            let expectation = expectation(description: "Complex filter")

            _ = reactor.action.onNext(.applyTagFilters(["소설", "추리"], favoriteOnly: true))

            _ = reactor.state
                .map { $0.filteredBooks }
                .filter { $0 != nil }
                .take(1)
                .subscribe(onNext: { filteredBooks in
                    // 결과 검증
                    XCTAssertNotNil(filteredBooks)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 3.0)
        }
    }

    // MARK: - Cascade Delete Performance

    func testPerformance_CascadeDeleteBookWithRelatedData() throws {
        // Given: 1권의 책 + 많은 관련 데이터
        let book = createMockBook()
        let bookId = String(describing: book.id)

        let quotes = createMockQuotes(count: 100, bookId: bookId)
        let tags = createMockTags(count: 20, bookId: bookId)

        // 사진은 실제 파일 없이 경로만 생성
        let photos = (0..<50).map { index in
            RealmPhoto(
                bookId: bookId,
                localImagePath: "/test/photo_\(index).jpg",
                createdAt: Date()
            )
        }

        try realm.write {
            realm.add(book)
            realm.add(quotes)
            realm.add(photos)
            realm.add(tags)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTStorageMetric()
        ]

        // When: Cascade 삭제
        measure(metrics: metrics) {
            let expectation = expectation(description: "Delete book")

            _ = bookRepository.deleteBookByISBN(book.isbn)
                .subscribe(onCompleted: {
                    // Then: 모든 관련 데이터 삭제 확인
                    let remainingQuotes = self.realm.objects(RealmQuote.self)
                        .filter("bookId == %@", bookId)
                    XCTAssertTrue(remainingQuotes.isEmpty)

                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 3.0)
        }

        // Baseline 기준: 100개 인용구 + 50개 사진 + 20개 태그 삭제는 500ms 이내
    }

    func testPerformance_DeleteMultipleBooksSequentially() throws {
        // Given: 100권의 책 (각각 소량의 관련 데이터 포함)
        let books = createMockBooks(count: 100)

        try realm.write {
            realm.add(books)

            for book in books {
                let bookId = String(describing: book.id)
                let quotes = createMockQuotes(count: 5, bookId: bookId)
                let tags = createMockTags(count: 3, bookId: bookId)
                realm.add(quotes)
                realm.add(tags)
            }
        }

        let isbns = books.map { $0.isbn }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]

        // When: 100권 순차 삭제
        measure(metrics: metrics) {
            let expectation = expectation(description: "Delete multiple books")

            _ = bookRepository.deleteBooksByISBNs(isbns)
                .subscribe(onCompleted: {
                    let remainingBooks = self.realm.objects(RealmBook.self)
                    XCTAssertTrue(remainingBooks.isEmpty)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Query Complexity Performance

    func testPerformance_ComplexJoinQuery() throws {
        // Given: 1000권 책 + 각 책당 평균 3개 태그
        let books = createMockBooks(count: 1000)
        let tags = createMockTags(for: books, tagsPerBook: 3)

        try realm.write {
            realm.add(books)
            realm.add(tags)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        // When: 특정 태그를 가진 책들을 찾고, 즐겨찾기 필터까지 적용
        measure(metrics: metrics) {
            let expectation = expectation(description: "Complex query")

            _ = tagRepository.getAllTags()
                .map { allTags -> [String] in
                    let filteredTags = allTags.filter { ["소설", "추리"].contains($0.tagName) }
                    let bookIds = Set(filteredTags.map { $0.bookId })

                    let filteredBooks = books.filter { book in
                        bookIds.contains(String(describing: book.id)) && book.isFavorite
                    }

                    return filteredBooks.map { $0.isbn }
                }
                .subscribe(onNext: { _ in
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Favorite Toggle Performance

    func testPerformance_ToggleFavoriteMultipleTimes() throws {
        // Given: 100권의 책
        let books = createMockBooks(count: 100)

        try realm.write {
            realm.add(books)
        }

        let bookIds = books.map { String(describing: $0.id) }

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        // When: 100권의 즐겨찾기 상태 토글
        measure(metrics: metrics) {
            let expectation = expectation(description: "Toggle favorites")
            expectation.expectedFulfillmentCount = bookIds.count

            for bookId in bookIds {
                _ = bookRepository.toggleFavorite(bookId: bookId)
                    .subscribe(onNext: { _ in
                        expectation.fulfill()
                    })
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Memory Leak Detection

    func testMemory_RepeatedRepositoryOperations() throws {
        // 반복적인 Repository 작업 시 메모리 누수 확인
        let metrics: [XCTMetric] = [
            XCTMemoryMetric()
        ]

        // Given: 소량의 데이터
        let books = createMockBooks(count: 10)
        try realm.write {
            realm.add(books)
        }

        // When: 100번 반복 조회
        measure(metrics: metrics) {
            let expectation = expectation(description: "Memory test")
            expectation.expectedFulfillmentCount = 100

            for _ in 0..<100 {
                _ = bookRepository.getAllBooksAsStruct()
                    .subscribe(onNext: { _ in
                        expectation.fulfill()
                    })
            }

            wait(for: [expectation], timeout: 10.0)
        }

        // Then: 메모리가 일정 수준 유지되어야 함 (누수 없음)
    }
}
