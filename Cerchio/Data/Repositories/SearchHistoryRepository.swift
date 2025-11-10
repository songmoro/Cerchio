//
//  SearchHistoryRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol SearchHistoryRepositoryProtocol {
    func getAllSearchHistory() -> Observable<[RealmSearchHistory]>
    func saveSearchHistory(keyword: String) -> Observable<RealmSearchHistory>
    func deleteSearchHistory(id: ObjectId) -> Observable<Void>
    func deleteAllSearchHistory() -> Observable<Void>
}

final class SearchHistoryRepository: BaseRepository<RealmSearchHistory>, SearchHistoryRepositoryProtocol {

    func getAllSearchHistory() -> Observable<[RealmSearchHistory]> {
        return sorted(by: "searchedAt", ascending: false)
    }

    func saveSearchHistory(keyword: String) -> Observable<RealmSearchHistory> {
        return performWriteTransaction {
            let existingHistory = self.realm.objects(RealmSearchHistory.self)
                .filter("keyword == %@", keyword)

            if let existing = existingHistory.first {
                self.realm.delete(existing)
            }

            let searchHistory = RealmSearchHistory(keyword: keyword, searchedAt: Date())
            self.realm.add(searchHistory)

            return searchHistory
        }
    }

    func deleteSearchHistory(id: ObjectId) -> Observable<Void> {
        return performWriteTransaction {
            if let history = self.realm.object(ofType: RealmSearchHistory.self, forPrimaryKey: id) {
                self.realm.delete(history)
            }
            return ()
        }
    }

    func deleteAllSearchHistory() -> Observable<Void> {
        return performWriteTransaction {
            let allHistory = self.realm.objects(RealmSearchHistory.self)
            self.realm.delete(allHistory)
            return ()
        }
    }

}
