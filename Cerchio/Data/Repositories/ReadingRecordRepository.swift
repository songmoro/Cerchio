//
//  ReadingRecordRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol ReadingRecordRepositoryProtocol {
    func getAllReadingRecords() -> Observable<[RealmReadingRecord]>
    func getReadingRecords(for bookId: String) -> Observable<[RealmReadingRecord]>
    func saveReadingRecord(_ record: RealmReadingRecord) -> Observable<RealmReadingRecord>
    func deleteReadingRecord(_ record: RealmReadingRecord) -> Observable<Void>
    func deleteReadingRecords(for bookId: String) -> Observable<Void>
}

final class ReadingRecordRepository: BaseRepository<RealmReadingRecord>, ReadingRecordRepositoryProtocol {

    // MARK: - ReadingRecordRepositoryProtocol
    func getAllReadingRecords() -> Observable<[RealmReadingRecord]> {
        return fetch()
    }

    func getReadingRecords(for bookId: String) -> Observable<[RealmReadingRecord]> {
        return filterAndSort(
            "bookId == %@",
            sortBy: "createdAt",
            ascending: false,
            bookId
        )
    }

    func saveReadingRecord(_ record: RealmReadingRecord) -> Observable<RealmReadingRecord> {
        return save(record)
    }

    func deleteReadingRecord(_ record: RealmReadingRecord) -> Observable<Void> {
        return delete(record)
    }

    func deleteReadingRecords(for bookId: String) -> Observable<Void> {
        return performWriteTransaction {
            let recordsToDelete = self.realm.objects(RealmReadingRecord.self).filter("bookId == %@", bookId)
            self.realm.delete(recordsToDelete)
            return ()
        }
    }

}
