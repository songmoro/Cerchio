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

    // MARK: - Helper Methods
    private func performWriteTransaction<U>(_ operation: @escaping () throws -> U) -> Observable<U> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let result = try self.realm.write {
                        try operation()
                    }
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(RepositoryError.transactionFailed(error))
                }
            }
            return Disposables.create()
        }
    }
}
