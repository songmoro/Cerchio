//
//  TagRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol TagRepositoryProtocol {
    func getAllTags() -> Observable<[RealmTag]>
    func getTags(for bookId: String) -> Observable<[RealmTag]>
    func getAllUniqueTagNames() -> Observable<[String]>
    func saveTags(_ tags: [RealmTag]) -> Observable<[RealmTag]>
    func deleteTag(_ tag: RealmTag) -> Observable<Void>
    func deleteTags(for bookId: String) -> Observable<Void>
}

final class TagRepository: BaseRepository<RealmTag>, TagRepositoryProtocol {

    func getAllTags() -> Observable<[RealmTag]> {
        return fetch()
    }

    func getTags(for bookId: String) -> Observable<[RealmTag]> {
        return filterAndSort(
            "bookId == %@",
            sortBy: "createdAt",
            ascending: true,
            bookId
        )
    }

    func getAllUniqueTagNames() -> Observable<[String]> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                let allTags = self.realm.objects(RealmTag.self)
                let uniqueTagNames = Array(Set(allTags.map { $0.tagName }))
                    .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                observer.onNext(uniqueTagNames)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func saveTags(_ tags: [RealmTag]) -> Observable<[RealmTag]> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    try self.realm.write {
                        self.realm.add(tags)
                    }
                    observer.onNext(tags)
                    observer.onCompleted()
                } catch {
                    observer.onError(RepositoryError.transactionFailed(error))
                }
            }
            return Disposables.create()
        }
    }

    func deleteTag(_ tag: RealmTag) -> Observable<Void> {
        return delete(tag)
    }

    func deleteTags(for bookId: String) -> Observable<Void> {
        return performWriteTransaction {
            let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookId)
            self.realm.delete(tagsToDelete)
            return ()
        }
    }

}
