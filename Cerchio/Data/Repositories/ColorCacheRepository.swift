import Foundation
import RealmSwift
import RxSwift

// MARK: - Protocol

protocol ColorCacheRepositoryProtocol {
    func getColorCache(forImageKey imageKey: String) -> Observable<RealmColorCache?>
    func saveColorCache(_ cache: RealmColorCache) -> Observable<RealmColorCache>
    func deleteColorCache(forImageKey imageKey: String) -> Observable<Void>
    func deleteOldCaches(olderThan date: Date) -> Observable<Void>
    func getAllCaches() -> Observable<[RealmColorCache]>
    func updateLastAccess(forImageKey imageKey: String) -> Observable<Void>
}

// MARK: - Implementation

final class ColorCacheRepository: BaseRepository<RealmColorCache>, ColorCacheRepositoryProtocol {
    func getColorCache(forImageKey imageKey: String) -> Observable<RealmColorCache?> {
        return findById(imageKey)
    }

    func saveColorCache(_ cache: RealmColorCache) -> Observable<RealmColorCache> {
        return save(cache)
    }

    func deleteColorCache(forImageKey imageKey: String) -> Observable<Void> {
        return performWriteTransaction {
            if let cache = self.realm.object(ofType: RealmColorCache.self, forPrimaryKey: imageKey) {
                self.realm.delete(cache)
            }
        }
    }

    func deleteOldCaches(olderThan date: Date) -> Observable<Void> {
        return performWriteTransaction {
            let oldCaches = self.realm.objects(RealmColorCache.self)
                .filter("lastAccessDate < %@", date)
            self.realm.delete(oldCaches)
        }
    }

    func getAllCaches() -> Observable<[RealmColorCache]> {
        return fetch()
    }

    func updateLastAccess(forImageKey imageKey: String) -> Observable<Void> {
        return performWriteTransaction {
            if let cache = self.realm.object(ofType: RealmColorCache.self, forPrimaryKey: imageKey) {
                cache.lastAccessDate = Date()
            }
        }
    }
}
