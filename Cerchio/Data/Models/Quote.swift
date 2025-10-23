//
//  Quote.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift

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

class RealmQuote: Object {
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
