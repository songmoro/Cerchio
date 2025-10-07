//
//  DebugLogRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 10/7/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol DebugLogRepositoryProtocol {
    func saveLog(_ log: DebugLog) -> Observable<DebugLog>
    func getAllLogs() -> Observable<[DebugLog]>
    func getLogs(category: String) -> Observable<[DebugLog]>
    func getLogs(level: LogLevel) -> Observable<[DebugLog]>
    func getLogs(since date: Date) -> Observable<[DebugLog]>
    func deleteOldLogs(olderThan date: Date) -> Observable<Void>
    func deleteAllLogs() -> Observable<Void>
}

final class DebugLogRepository: BaseRepository<RealmDebugLog>, DebugLogRepositoryProtocol {

    func saveLog(_ log: DebugLog) -> Observable<DebugLog> {
        return performWriteTransaction {
            let realmLog = log.toRealmDebugLog()
            self.realm.add(realmLog)
            return realmLog.toDebugLog()
        }
    }

    func getAllLogs() -> Observable<[DebugLog]> {
        return sorted(by: "timestamp", ascending: false)
            .map { $0.map { $0.toDebugLog() } }
    }

    func getLogs(category: String) -> Observable<[DebugLog]> {
        return filterAndSort("category == %@", sortBy: "timestamp", ascending: false, category)
            .map { $0.map { $0.toDebugLog() } }
    }

    func getLogs(level: LogLevel) -> Observable<[DebugLog]> {
        return filterAndSort("level == %@", sortBy: "timestamp", ascending: false, level.rawValue)
            .map { $0.map { $0.toDebugLog() } }
    }

    func getLogs(since date: Date) -> Observable<[DebugLog]> {
        return filterAndSort("timestamp >= %@", sortBy: "timestamp", ascending: false, date)
            .map { $0.map { $0.toDebugLog() } }
    }

    func deleteOldLogs(olderThan date: Date) -> Observable<Void> {
        return performWriteTransaction {
            let oldLogs = self.realm.objects(RealmDebugLog.self).filter("timestamp < %@", date)
            self.realm.delete(oldLogs)
            return ()
        }
    }

    func deleteAllLogs() -> Observable<Void> {
        return deleteAll()
    }
}
