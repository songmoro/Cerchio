//
//  TestHelpers.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import XCTest
import UIKit
import RealmSwift
@testable import Cerchio

// MARK: - Test Helpers Extension

extension XCTestCase {

    // MARK: - Mock Books

    /// Creates mock books for testing
    /// - Parameter count: Number of books to create
    /// - Returns: Array of RealmBook objects
    func createMockBooks(count: Int) -> [RealmBook] {
        return (0..<count).map { index in
            let book = RealmBook()
            book.title = "테스트 도서 \(index)"
            book.cleanTitle = "테스트 도서 \(index)"
            book.isbn = String(format: "%013d", 1000000000000 + index)
            book.author = "작가 \(index % 50)"
            book.publisher = "출판사 \(index % 20)"
            book.link = "https://example.com/book/\(index)"
            book.image = "https://example.com/image/\(index).jpg"
            book.bookDescription = "테스트 도서 설명 \(index). 이것은 충분히 긴 설명을 만들기 위한 더미 데이터입니다."
            book.cleanDescription = "테스트 도서 설명 \(index)"
            book.pubdate = "20240101"
            book.discount = "\(15000 + index * 100)"
            book.formattedPrice = "\(15000 + index * 100)원"
            book.priceAsInt = 15000 + index * 100
            book.isFavorite = index % 3 == 0
            book.totalPages = 200 + (index % 500)
            book.createAt = Date().addingTimeInterval(TimeInterval(-index * 86400))

            if index % 2 == 0 {
                book.startDate = Date().addingTimeInterval(TimeInterval(-index * 86400))
            }
            if index % 4 == 0 {
                book.endDate = Date().addingTimeInterval(TimeInterval(-index * 43200))
            }

            return book
        }
    }

    /// Creates a single mock book with custom properties
    func createMockBook(
        title: String = "샘플 도서",
        isbn: String = "1234567890123",
        author: String = "샘플 작가",
        isFavorite: Bool = false
    ) -> RealmBook {
        let book = RealmBook()
        book.title = title
        book.cleanTitle = title
        book.isbn = isbn
        book.author = author
        book.publisher = "샘플 출판사"
        book.link = "https://example.com/book"
        book.image = "https://example.com/image.jpg"
        book.bookDescription = "샘플 도서 설명"
        book.cleanDescription = "샘플 도서 설명"
        book.pubdate = "20240101"
        book.discount = "15000"
        book.formattedPrice = "15000원"
        book.priceAsInt = 15000
        book.isFavorite = isFavorite
        book.totalPages = 300
        book.createAt = Date()
        return book
    }

    // MARK: - Mock Tags

    /// Creates mock tags for books
    /// - Parameters:
    ///   - books: Books to create tags for
    ///   - tagsPerBook: Number of tags per book
    /// - Returns: Array of RealmTag objects
    func createMockTags(for books: [RealmBook], tagsPerBook: Int) -> [RealmTag] {
        let tagNames = ["소설", "추리", "SF", "판타지", "로맨스", "역사", "자기계발", "에세이", "철학", "과학"]

        return books.flatMap { book in
            (0..<tagsPerBook).map { index in
                let tag = RealmTag(
                    bookId: String(describing: book.id),
                    tagName: tagNames[index % tagNames.count],
                    createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
                )
                return tag
            }
        }
    }

    /// Creates mock tags with specific count and bookId
    func createMockTags(count: Int, bookId: String) -> [RealmTag] {
        let tagNames = ["소설", "추리", "SF", "판타지", "로맨스", "역사", "자기계발", "에세이"]

        return (0..<count).map { index in
            RealmTag(
                bookId: bookId,
                tagName: tagNames[index % tagNames.count],
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
            )
        }
    }

    // MARK: - Mock Quotes

    /// Creates mock quotes for a book
    /// - Parameters:
    ///   - count: Number of quotes to create
    ///   - bookId: Book ID to associate quotes with
    /// - Returns: Array of RealmQuote objects
    func createMockQuotes(count: Int, bookId: String) -> [RealmQuote] {
        let quoteSamples = [
            "인생은 B(Birth)와 D(Death) 사이의 C(Choice)이다.",
            "꿈을 계속 간직하고 있으면 반드시 실현할 때가 온다.",
            "행복의 한 쪽 문이 닫히면 다른 쪽 문이 열린다.",
            "진정으로 웃으려면 고통을 참아야하며, 나아가 고통을 즐길 줄 알아야 한다.",
            "성공이란 열정을 잃지 않고 실패를 거듭할 수 있는 능력이다."
        ]

        var quotes: [RealmQuote] = []
        for index in 0..<count {
            let quoteText = quoteSamples[index % quoteSamples.count] + " (\(index))"
            let note: String? = (index % 3 == 0) ? "테스트 메모 \(index)" : nil
            let date = Date().addingTimeInterval(TimeInterval(-index * 1800))

            let quote = RealmQuote(
                bookId: bookId,
                quote: quoteText,
                pageNumber: index % 300,
                note: note,
                createdAt: date
            )
            quotes.append(quote)
        }
        return quotes
    }

    // MARK: - Mock Photos

    /// Creates mock photos with actual image files
    /// - Parameters:
    ///   - count: Number of photos to create
    ///   - bookId: Book ID to associate photos with
    /// - Returns: Array of RealmPhoto objects
    /// - Throws: If image creation or storage fails
    func createMockPhotos(count: Int, bookId: String) throws -> [RealmPhoto] {
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]

        return try (0..<count).map { index in
            let color = colors[index % colors.count]
            let image = createDummyImage(size: CGSize(width: 800, height: 600), backgroundColor: color)

            let imageName = "test_\(bookId)_\(index)_\(UUID().uuidString)"
            guard let path = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                throw TestError.imageCreationFailed
            }

            return RealmPhoto(
                bookId: bookId,
                localImagePath: path,
                pageNumber: index % 300,
                note: index % 2 == 0 ? "테스트 사진 메모 \(index)" : nil,
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 1800))
            )
        }
    }

    /// Creates a dummy image with specified size and background color
    private func createDummyImage(size: CGSize, backgroundColor: UIColor = .systemBlue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "\(Int(size.width))x\(Int(size.height))" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    // MARK: - Cleanup

    /// Cleans up test images created during tests
    /// - Parameter bookId: Book ID to clean up images for
    func cleanupTestImages(for bookId: String) {
        _ = ImageStorageManager.shared.deleteAllImages(for: bookId)
    }

    /// Cleans up all test images
    func cleanupAllTestImages() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesPath = documentsPath.appendingPathComponent("BookPhotos", isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesPath.path) else {
            return
        }

        for file in files where file.hasPrefix("test_") {
            let filePath = imagesPath.appendingPathComponent(file).path
            _ = ImageStorageManager.shared.deleteImage(atPath: filePath)
        }
    }
}

// MARK: - Test Error

enum TestError: Error {
    case imageCreationFailed
    case realmSetupFailed
    case dataNotFound

    var localizedDescription: String {
        switch self {
        case .imageCreationFailed:
            return "Failed to create test image"
        case .realmSetupFailed:
            return "Failed to setup test Realm"
        case .dataNotFound:
            return "Test data not found"
        }
    }
}

// MARK: - Equatable Helpers for Testing

extension Book {
    /// Compares two books ignoring IDs and timestamps
    func isEqualIgnoringMetadata(to other: Book) -> Bool {
        return self.title == other.title &&
               self.isbn == other.isbn &&
               self.author == other.author &&
               self.publisher == other.publisher
    }
}

extension Tag {
    /// Compares two tags ignoring IDs and timestamps
    func isEqualIgnoringMetadata(to other: Tag) -> Bool {
        return self.bookId == other.bookId &&
               self.tagName == other.tagName
    }
}
