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
    func deleteAllSearchHistory() -> Observable<Void>
}

final class SearchHistoryRepository: BaseRepository<RealmSearchHistory>, SearchHistoryRepositoryProtocol {

    func getAllSearchHistory() -> Observable<[RealmSearchHistory]> {
        return sorted(by: "searchedAt", ascending: false)
    }

    func saveSearchHistory(keyword: String) -> Observable<RealmSearchHistory> {
        let searchHistory = RealmSearchHistory(keyword: keyword, searchedAt: Date())
        return save(searchHistory)
    }

    func deleteAllSearchHistory() -> Observable<Void> {
        return performWriteTransaction {
            let allHistory = self.realm.objects(RealmSearchHistory.self)
            self.realm.delete(allHistory)
            return ()
        }
    }

}
