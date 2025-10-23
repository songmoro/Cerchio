//
//  BookSearchMapper.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

struct BookSearchMapper {

    static func mapToBook(_ item: BookSearchItem) -> Book {
        return Book(
            title: item.cleanTitle,
            image: item.image,
            author: item.author,
            isbn: item.isbn,
            genre: nil,
            totalPages: nil,
            isFavorite: false,
            dateAdded: Date(),
            dateRead: nil,
            readingStatus: .toRead,
            category: nil,
            rating: nil
        )
    }

    static func mapToRealmBook(_ item: BookSearchItem) -> RealmBook {
        return RealmBook(
            title: item.title,
            link: item.link,
            image: item.image,
            author: item.author,
            discount: item.discount,
            publisher: item.publisher,
            isbn: item.isbn,
            description: item.description,
            pubdate: item.pubdate,
            cleanTitle: item.cleanTitle,
            cleanDescription: item.cleanDescription,
            formattedPubDate: item.formattedPubDate,
            formattedPrice: item.formattedPrice,
            priceAsInt: item.priceAsInt,
            createAt: Date()
        )
    }

    static func mapToBooks(_ items: [BookSearchItem]) -> [Book] {
        return items.map { mapToBook($0) }
    }

    static func mapToRealmBooks(_ items: [BookSearchItem]) -> [RealmBook] {
        return items.map { mapToRealmBook($0) }
    }

    static func mapResponseToBooks(_ response: BookSearchResponse) -> [Book] {
        return mapToBooks(response.items)
    }

    static func mapResponseToRealmBooks(_ response: BookSearchResponse) -> [RealmBook] {
        return mapToRealmBooks(response.items)
    }

}

struct BookSearchResult {
    let books: [Book]
    let totalCount: Int
    let currentPage: Int
    let pageSize: Int
    let hasNextPage: Bool

    init(response: BookSearchResponse, pageSize: Int) {
        self.books = BookSearchMapper.mapResponseToBooks(response)
        self.totalCount = response.total
        self.currentPage = (response.start - 1) / pageSize + 1
        self.pageSize = pageSize
        self.hasNextPage = response.start + response.display <= response.total
    }
}

extension BookSearchItem {
    func toBook() -> Book {
        return BookSearchMapper.mapToBook(self)
    }

    func toRealmBook() -> RealmBook {
        return BookSearchMapper.mapToRealmBook(self)
    }
}

extension BookSearchResponse {
    func toBooks() -> [Book] {
        return BookSearchMapper.mapResponseToBooks(self)
    }

    func toRealmBooks() -> [RealmBook] {
        return BookSearchMapper.mapResponseToRealmBooks(self)
    }

    func toBookSearchResult(pageSize: Int) -> BookSearchResult {
        return BookSearchResult(response: self, pageSize: pageSize)
    }
}

struct BookSearchMetadata {
    let query: String
    let totalResults: Int
    let searchDuration: TimeInterval?
    let timestamp: Date

    init(query: String, response: BookSearchResponse, searchDuration: TimeInterval? = nil) {
        self.query = query
        self.totalResults = response.total
        self.searchDuration = searchDuration
        self.timestamp = Date()
    }
}