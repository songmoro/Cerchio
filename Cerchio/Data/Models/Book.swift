//
//  Book.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit
import RealmSwift

class RealmBook: Object, Sendable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var link: String
    @Persisted var image: String
    @Persisted var author: String
    @Persisted var discount: String?
    @Persisted var publisher: String
    @Persisted var isbn: String
    @Persisted var bookDescription: String
    @Persisted var pubdate: String
    @Persisted var cleanTitle: String
    @Persisted var cleanDescription: String
    @Persisted var formattedPubDate: Date?
    @Persisted var formattedPrice: String?
    @Persisted var priceAsInt: Int?
    @Persisted var createAt: Date
    @Persisted var isFavorite: Bool = false
    @Persisted var totalPages: Int = 0
    @Persisted var startDate: Date?
    @Persisted var endDate: Date?

    convenience init(title: String, link: String, image: String, author: String, discount: String? = nil, publisher: String, isbn: String, description: String, pubdate: String, cleanTitle: String, cleanDescription: String, formattedPubDate: Date? = nil, formattedPrice: String? = nil, priceAsInt: Int? = nil, createAt: Date = Date(), isFavorite: Bool = false, totalPages: Int = 0, startDate: Date? = nil, endDate: Date? = nil) {
        self.init()
        self.title = title
        self.link = link
        self.image = image
        self.author = author
        self.discount = discount
        self.publisher = publisher
        self.isbn = isbn
        self.bookDescription = description
        self.pubdate = pubdate
        self.cleanTitle = cleanTitle
        self.cleanDescription = cleanDescription
        self.formattedPubDate = formattedPubDate
        self.formattedPrice = formattedPrice
        self.priceAsInt = priceAsInt
        self.createAt = createAt
        self.isFavorite = isFavorite
        self.totalPages = totalPages
        self.startDate = startDate
        self.endDate = endDate
    }
}

nonisolated struct Book: Hashable, Codable {
    let id: String
    let title: String
    let cleanTitle: String
    let link: String
    let image: String
    let author: String
    let isbn: String
    let publisher: String
    let bookDescription: String
    let cleanDescription: String
    let pubdate: String
    let discount: String?
    let formattedPubDate: Date?
    let formattedPrice: String?
    let priceAsInt: Int?
    let createAt: Date

    // Extended properties for feature models
    let genre: String?
    let totalPages: Int?
    let startDate: Date?
    let endDate: Date?
    let isFavorite: Bool
    let dateAdded: Date?
    let dateRead: Date?
    let readingStatus: ReadingStatus?
    let category: BookCategory?
    let rating: Int?

    init(
        id: String = UUID().uuidString,
        title: String,
        cleanTitle: String? = nil,
        link: String = "",
        image: String,
        author: String,
        isbn: String,
        publisher: String = "",
        bookDescription: String = "",
        cleanDescription: String = "",
        pubdate: String = "",
        discount: String? = nil,
        formattedPubDate: Date? = nil,
        formattedPrice: String? = nil,
        priceAsInt: Int? = nil,
        createAt: Date = Date(),
        genre: String? = nil,
        totalPages: Int? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isFavorite: Bool = false,
        dateAdded: Date? = nil,
        dateRead: Date? = nil,
        readingStatus: ReadingStatus? = nil,
        category: BookCategory? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.cleanTitle = cleanTitle ?? title
        self.link = link
        self.image = image
        self.author = author
        self.isbn = isbn
        self.publisher = publisher
        self.bookDescription = bookDescription
        self.cleanDescription = cleanDescription
        self.pubdate = pubdate
        self.discount = discount
        self.formattedPubDate = formattedPubDate
        self.formattedPrice = formattedPrice
        self.priceAsInt = priceAsInt
        self.createAt = createAt
        self.genre = genre
        self.totalPages = totalPages
        self.startDate = startDate
        self.endDate = endDate
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.dateRead = dateRead
        self.readingStatus = readingStatus
        self.category = category
        self.rating = rating
    }
    
    static let sample: [Book] = [
        Book(
            title: "센과 치히로의 행방불명",
            image: "https://i.imgur.com/J8Y8j5k.png",
            author: "미야자키 하야오",
            isbn: "9788954675291",
            genre: "아동문학",
            totalPages: 192,
            isFavorite: true
        ),
        Book(
            title: "해리 포터와 마법사의 돌",
            image: "https://i.imgur.com/8y7s3m3.jpg",
            author: "J.K. 롤링",
            isbn: "9788983920102",
            genre: "판타지",
            totalPages: 448,
            isFavorite: false
        ),
        Book(
            title: "어린 왕자",
            image: "https://i.imgur.com/5k2R9Xh.jpg",
            author: "앙투안 드 생텍쥐페리",
            isbn: "9788932917245",
            genre: "소설",
            totalPages: 112,
            isFavorite: true
        ),
        Book(
            title: "1984",
            image: "https://i.imgur.com/3x7J8K9.jpg",
            author: "조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰 조지 오웰",
            isbn: "9788937460777",
            genre: "SF",
            totalPages: 448,
            isFavorite: false
        ),
        Book(
            title: "데미안 데미안 데미안 데미안 데미안 데미안 데미안 데미안 데미안 데미안 데미안 데미안",
            image: "https://i.imgur.com/9K8J3m2.jpg",
            author: "헤르만 헤세",
            isbn: "9788937462788",
            genre: "소설",
            totalPages: 288,
            isFavorite: true
        ),
        Book(
            title: "죄와 벌",
            image: "https://i.imgur.com/7Y4K8m3.jpg",
            author: "표도르 도스토옙스키",
            isbn: "9788937462009",
            genre: "고전문학",
            totalPages: 864,
            isFavorite: false
        ),
        Book(
            title: "호밀밭의 파수꾼",
            image: "https://i.imgur.com/2K8Y3j7.jpg",
            author: "J.D. 샐린저",
            isbn: "9788982814471",
            genre: "소설",
            totalPages: 336,
            isFavorite: true
        ),
        Book(
            title: "위대한 개츠비",
            image: "https://i.imgur.com/5m3K8Y7.jpg",
            author: "F. 스콧 피츠제럴드",
            isbn: "9788937460784",
            genre: "고전문학",
            totalPages: 256,
            isFavorite: false
        ),
        Book(
            title: "노인과 바다",
            image: "https://i.imgur.com/8K3Y7m2.jpg",
            author: "어니스트 헤밍웨이",
            isbn: "9788937460456",
            genre: "고전문학",
            totalPages: 144,
            isFavorite: true
        ),
        Book(
            title: "반지의 제왕",
            image: "https://i.imgur.com/3Y8K2m7.jpg",
            author: "J.R.R. 톨킨",
            isbn: "9788983920591",
            genre: "판타지",
            totalPages: 1216,
            isFavorite: false
        )
    ]
}

// MARK: - Photo Struct (for UI)

nonisolated struct Photo: Hashable, Sendable {
    let id: String
    let bookId: String
    let localImagePath: String
    let pageNumber: Int?
    let note: String?
    let createdAt: Date

    init(id: String, bookId: String, localImagePath: String, pageNumber: Int? = nil, note: String? = nil, createdAt: Date) {
        self.id = id
        self.bookId = bookId
        self.localImagePath = localImagePath
        self.pageNumber = pageNumber
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - RealmPhoto Model

class RealmPhoto: Object, Sendable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var bookId: String
    @Persisted var localImagePath: String
    @Persisted var pageNumber: Int?
    @Persisted var note: String?
    @Persisted var createdAt: Date

    convenience init(
        bookId: String,
        localImagePath: String,
        pageNumber: Int? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.init()
        self.bookId = bookId
        self.localImagePath = localImagePath
        self.pageNumber = pageNumber
        self.note = note
        self.createdAt = createdAt
    }

    func toPhoto() -> Photo {
        return Photo(
            id: String(describing: id),
            bookId: bookId,
            localImagePath: localImagePath,
            pageNumber: pageNumber,
            note: note,
            createdAt: createdAt
        )
    }
}

// MARK: - Quote Struct (for UI)

nonisolated struct Quote: Hashable, Sendable {
    let id: String
    let bookId: String
    let quote: String
    let pageNumber: Int?
    let note: String?
    let createdAt: Date

    init(id: String, bookId: String, quote: String, pageNumber: Int? = nil, note: String? = nil, createdAt: Date) {
        self.id = id
        self.bookId = bookId
        self.quote = quote
        self.pageNumber = pageNumber
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - RealmQuote Model

class RealmQuote: Object, Sendable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var bookId: String
    @Persisted var quote: String
    @Persisted var pageNumber: Int?
    @Persisted var note: String?
    @Persisted var createdAt: Date

    convenience init(
        bookId: String,
        quote: String,
        pageNumber: Int? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.init()
        self.bookId = bookId
        self.quote = quote
        self.pageNumber = pageNumber
        self.note = note
        self.createdAt = createdAt
    }

    func toQuote() -> Quote {
        return Quote(
            id: String(describing: id),
            bookId: bookId,
            quote: quote,
            pageNumber: pageNumber,
            note: note,
            createdAt: createdAt
        )
    }
}

// MARK: - RealmBook Extensions

extension RealmBook {
    /// Converts RealmBook to Book model
    func toBook() -> Book {
        return Book(
            id: String(describing: id),
            title: title,
            cleanTitle: cleanTitle,
            link: link,
            image: image,
            author: author,
            isbn: isbn,
            publisher: publisher,
            bookDescription: bookDescription,
            cleanDescription: cleanDescription,
            pubdate: pubdate,
            discount: discount,
            formattedPubDate: formattedPubDate,
            formattedPrice: formattedPrice,
            priceAsInt: priceAsInt,
            createAt: createAt,
            genre: nil,
            totalPages: totalPages > 0 ? totalPages : nil,
            startDate: startDate,
            endDate: endDate,
            isFavorite: isFavorite,
            dateAdded: createAt,
            dateRead: nil,
            readingStatus: .toRead,
            category: nil,
            rating: nil
        )
    }
}

// MARK: - Book Extensions

extension Book {
    /// Converts Book to RealmBook model
    func toRealmBook() -> RealmBook {
        return RealmBook(
            title: title,
            link: link,
            image: image,
            author: author,
            discount: discount,
            publisher: publisher,
            isbn: isbn,
            description: bookDescription,
            pubdate: pubdate,
            cleanTitle: cleanTitle,
            cleanDescription: cleanDescription,
            formattedPubDate: formattedPubDate,
            formattedPrice: formattedPrice,
            priceAsInt: priceAsInt,
            createAt: createAt,
            isFavorite: isFavorite,
            totalPages: totalPages ?? 0,
            startDate: startDate,
            endDate: endDate
        )
    }
}
