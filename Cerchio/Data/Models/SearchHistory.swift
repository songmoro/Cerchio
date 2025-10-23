//
//  SearchHistory.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift

final class RealmSearchHistory: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var keyword: String
    @Persisted var searchedAt: Date

    convenience init(keyword: String, searchedAt: Date = Date()) {
        self.init()
        self.keyword = keyword
        self.searchedAt = searchedAt
    }
}

struct SearchHistory: Hashable, Sendable {
    let id: String
    let keyword: String
    let searchedAt: Date

    init(id: String = UUID().uuidString, keyword: String, searchedAt: Date = Date()) {
        self.id = id
        self.keyword = keyword
        self.searchedAt = searchedAt
    }
}

extension RealmSearchHistory {
    func toSearchHistory() -> SearchHistory {
        return SearchHistory(
            id: String(describing: id),
            keyword: keyword,
            searchedAt: searchedAt
        )
    }
}

extension SearchHistory {
    func toRealmSearchHistory() -> RealmSearchHistory {
        let realmHistory = RealmSearchHistory()
        if let objectId = try? ObjectId(string: id) {
            realmHistory.id = objectId
        }
        realmHistory.keyword = keyword
        realmHistory.searchedAt = searchedAt
        return realmHistory
    }
}
