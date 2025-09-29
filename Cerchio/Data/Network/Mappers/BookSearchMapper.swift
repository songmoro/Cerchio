//
//  BookSearchMapper.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

// MARK: - Book Search Result Mapper

struct BookSearchMapper {

    /// Maps a BookSearchItem to a Book model
    static func mapToBook(_ item: BookSearchItem) -> Book {
        return Book(
            title: item.cleanTitle,
            image: item.image,
            author: item.author,
            isbn: item.isbn,
            genre: nil, // Not provided by Naver API
            totalPages: nil, // Not provided by Naver API
            isFavorite: false,
            dateAdded: Date(),
            dateRead: nil,
            readingStatus: .toRead,
            category: nil, // Not provided by Naver API
            rating: nil
        )
    }

    /// Maps a BookSearchItem to a RealmBook model (preserves all network response data)
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

    /// Maps an array of BookSearchItems to an array of Book models
    static func mapToBooks(_ items: [BookSearchItem]) -> [Book] {
        return items.map { mapToBook($0) }
    }

    /// Maps an array of BookSearchItems to an array of RealmBook models
    static func mapToRealmBooks(_ items: [BookSearchItem]) -> [RealmBook] {
        return items.map { mapToRealmBook($0) }
    }

    /// Maps BookSearchResponse to an array of Book models
    static func mapResponseToBooks(_ response: BookSearchResponse) -> [Book] {
        return mapToBooks(response.items)
    }

    /// Maps BookSearchResponse to an array of RealmBook models
    static func mapResponseToRealmBooks(_ response: BookSearchResponse) -> [RealmBook] {
        return mapToRealmBooks(response.items)
    }

}

// MARK: - Search Result Wrapper

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

// MARK: - Extensions

extension BookSearchItem {
    /// Converts BookSearchItem to Book model
    func toBook() -> Book {
        return BookSearchMapper.mapToBook(self)
    }

    /// Converts BookSearchItem to RealmBook model (preserves all network response data)
    func toRealmBook() -> RealmBook {
        return BookSearchMapper.mapToRealmBook(self)
    }
}

extension BookSearchResponse {
    /// Converts BookSearchResponse to an array of Book models
    func toBooks() -> [Book] {
        return BookSearchMapper.mapResponseToBooks(self)
    }

    /// Converts BookSearchResponse to an array of RealmBook models
    func toRealmBooks() -> [RealmBook] {
        return BookSearchMapper.mapResponseToRealmBooks(self)
    }

    /// Converts BookSearchResponse to BookSearchResult with pagination info
    func toBookSearchResult(pageSize: Int) -> BookSearchResult {
        return BookSearchResult(response: self, pageSize: pageSize)
    }
}

// MARK: - Search Metadata

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