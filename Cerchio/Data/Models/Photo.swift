//
//  Photo.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift

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

class RealmPhoto: Object {
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
