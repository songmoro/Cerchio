//
//  ReadingRecord.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import RealmSwift

nonisolated struct ReadingRecord: Hashable, Sendable {
    let id: String
    let bookId: String
    let content: String
    let createdAt: Date

    init(id: String, bookId: String, content: String, createdAt: Date) {
        self.id = id
        self.bookId = bookId
        self.content = content
        self.createdAt = createdAt
    }
}

class RealmReadingRecord: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var bookId: String
    @Persisted var content: String
    @Persisted var createdAt: Date

    convenience init(
        bookId: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.init()
        self.bookId = bookId
        self.content = content
        self.createdAt = createdAt
    }

    func toReadingRecord() -> ReadingRecord {
        return ReadingRecord(
            id: String(describing: id),
            bookId: bookId,
            content: content,
            createdAt: createdAt
        )
    }
}
