//
//  Book.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import Foundation
import RealmSwift

class RealmBook: Object {
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

    @Persisted var customTitle: String?
    @Persisted var customAuthor: String?
    @Persisted var customCoverImagePath: String?

    convenience init(title: String, link: String, image: String, author: String, discount: String? = nil, publisher: String, isbn: String, description: String, pubdate: String, cleanTitle: String, cleanDescription: String, formattedPubDate: Date? = nil, formattedPrice: String? = nil, priceAsInt: Int? = nil, createAt: Date = Date(), isFavorite: Bool = false, totalPages: Int = 0, startDate: Date? = nil, endDate: Date? = nil, customTitle: String? = nil, customAuthor: String? = nil, customCoverImagePath: String? = nil) {
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
        self.customTitle = customTitle
        self.customAuthor = customAuthor
        self.customCoverImagePath = customCoverImagePath
    }
}

nonisolated struct Book: Hashable, Codable {
    let id: String
    let title: String
    private let _cleanTitle: String
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

    let customTitle: String?
    let customAuthor: String?
    let customCoverImagePath: String?

    // Computed property: customTitle이 nil이 아니면 customTitle, 그렇지 않으면 원본 cleanTitle
    var cleanTitle: String {
        return customTitle ?? _cleanTitle
    }

    // 원본 cleanTitle (placeholder용)
    var originalCleanTitle: String {
        return _cleanTitle
    }

    enum CodingKeys: String, CodingKey {
        case id, title, link, image, author, isbn, publisher, bookDescription, cleanDescription
        case pubdate, discount, formattedPubDate, formattedPrice, priceAsInt, createAt
        case genre, totalPages, startDate, endDate, isFavorite, dateAdded, dateRead
        case readingStatus, category, rating
        case customTitle, customAuthor, customCoverImagePath
        case _cleanTitle = "cleanTitle"
    }

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
        rating: Int? = nil,
        customTitle: String? = nil,
        customAuthor: String? = nil,
        customCoverImagePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self._cleanTitle = cleanTitle ?? title
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
        self.customTitle = customTitle
        self.customAuthor = customAuthor
        self.customCoverImagePath = customCoverImagePath
    }

    var displayTitle: String {
        return customTitle ?? title
    }

    var displayAuthor: String {
        return customAuthor ?? author
    }

    var displayImage: String {
        return customCoverImagePath ?? image
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
            rating: nil,
            customTitle: customTitle,
            customAuthor: customAuthor,
            customCoverImagePath: customCoverImagePath
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
            endDate: endDate,
            customTitle: customTitle,
            customAuthor: customAuthor,
            customCoverImagePath: customCoverImagePath
        )
    }
}
