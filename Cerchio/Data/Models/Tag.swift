//
//  Tag.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift

class RealmTag: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var bookId: String
    @Persisted var tagName: String
    @Persisted var createdAt: Date

    convenience init(
        bookId: String,
        tagName: String,
        createdAt: Date = Date()
    ) {
        self.init()
        self.bookId = bookId
        self.tagName = tagName
        self.createdAt = createdAt
    }

    func toTag() -> Tag {
        return Tag(
            id: String(describing: id),
            bookId: bookId,
            tagName: tagName,
            createdAt: createdAt
        )
    }
}

nonisolated struct Tag: Hashable, Sendable {
    let id: String
    let bookId: String
    let tagName: String
    let createdAt: Date

    init(id: String, bookId: String, tagName: String, createdAt: Date) {
        self.id = id
        self.bookId = bookId
        self.tagName = tagName
        self.createdAt = createdAt
    }
}
