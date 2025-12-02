import UIKit
import RxSwift

final class DominantColorCache {
    static let shared = DominantColorCache()

    private let cache = NSCache<NSString, NSArray>()
    private let queue = DispatchQueue(label: "com.cerchio.dominantColorCache", attributes: .concurrent)

    private var scopedImageKeys: [String: Set<String>] = [:]
    private let scopeQueue = DispatchQueue(label: "com.cerchio.dominantColorCache.scope", attributes: .concurrent)

    private let repository: ColorCacheRepositoryProtocol
    private let disposeBag = DisposeBag()

    // Cache statistics
    private var memoryHitCount: Int = 0
    private var persistentHitCount: Int = 0
    private var missCount: Int = 0
    private let statsQueue = DispatchQueue(label: "com.cerchio.dominantColorCache.stats", attributes: .concurrent)

    var memoryCacheCountLimit: Int = 100 {
        didSet {
            cache.countLimit = memoryCacheCountLimit
        }
    }

    var memoryCacheTotalCostLimit: Int = 5 * 1024 * 1024 {
        didSet {
            cache.totalCostLimit = memoryCacheTotalCostLimit
        }
    }

    private init() {
        self.repository = ServiceFactory.build().createColorCacheRepository()

        cache.countLimit = memoryCacheCountLimit
        cache.totalCostLimit = memoryCacheTotalCostLimit
    }

    func getColors(forImageKey imageKey: String) -> [UIColor]? {
        return queue.sync { [weak self] in
            guard let self = self else { return nil }

            if let cachedColors = self.cache.object(forKey: imageKey as NSString) as? [UIColor] {
                self.incrementMemoryHit()
                self.updateLastAccessAsync(forImageKey: imageKey)
                return cachedColors
            }

            return nil
        }
    }

    func recordPersistentHit() {
        incrementPersistentHit()
    }

    func recordMiss() {
        incrementMiss()
    }

    func setColors(_ colors: [UIColor], forImageKey imageKey: String, scope: String? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // 이미지당 약 50KB로 추정하여 cost 계산
            let cost = 50 * 1024
            self.cache.setObject(colors as NSArray, forKey: imageKey as NSString, cost: cost)

            let realmCache = RealmColorCache(imageKey: imageKey, colors: colors)
            self.repository.saveColorCache(realmCache)
                .subscribe()
                .disposed(by: self.disposeBag)
        }

        if let scope = scope {
            scopeQueue.async(flags: .barrier) { [weak self] in
                self?.scopedImageKeys[scope, default: []].insert(imageKey)
            }
        }
    }

    func removeColors(forImageKey imageKey: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.cache.removeObject(forKey: imageKey as NSString)

            self.repository.deleteColorCache(forImageKey: imageKey)
                .subscribe()
                .disposed(by: self.disposeBag)
        }

        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedImageKeys.forEach { key, _ in
                self?.scopedImageKeys[key]?.remove(imageKey)
            }
        }
    }

    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAllObjects()
        }

        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedImageKeys.removeAll()
        }
    }

    func clearScope(_ scopeId: String) {
        scopeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let imageKeys = self.scopedImageKeys[scopeId] else {
                return
            }

            self.queue.async(flags: .barrier) { [weak self] in
                imageKeys.forEach { imageKey in
                    self?.cache.removeObject(forKey: imageKey as NSString)
                }
            }

            self.scopedImageKeys.removeValue(forKey: scopeId)
        }
    }

    func registerScope(_ scopeId: String, imageKeys: [String]) {
        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedImageKeys[scopeId] = Set(imageKeys)
        }
    }

    func loadAndCacheColors(imageKeys: [String], scope: String?) async {
        for imageKey in imageKeys {
            guard getColors(forImageKey: imageKey) == nil else { continue }

            let colors: [UIColor]? = await withCheckedContinuation { continuation in
                repository.getColorCache(forImageKey: imageKey)
                    .subscribe(onNext: { cache in
                        if let cache = cache,
                           let colors = [UIColor].fromData(cache.colorData) {
                            continuation.resume(returning: colors)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }, onError: { _ in
                        continuation.resume(returning: nil)
                    })
                    .disposed(by: disposeBag)
            }

            if let colors = colors {
                incrementPersistentHit()

                queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    // 이미지당 약 50KB로 추정하여 cost 계산
                    let cost = 50 * 1024
                    self.cache.setObject(colors as NSArray, forKey: imageKey as NSString, cost: cost)
                }

                if let scope = scope {
                    scopeQueue.async(flags: .barrier) { [weak self] in
                        self?.scopedImageKeys[scope, default: []].insert(imageKey)
                    }
                }
            }
        }
    }

    private func updateLastAccessAsync(forImageKey imageKey: String) {
        repository.updateLastAccess(forImageKey: imageKey)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func cleanupOldCaches(maxAge: TimeInterval = 30 * 24 * 60 * 60) {
        let cutoffDate = Date().addingTimeInterval(-maxAge)
        repository.deleteOldCaches(olderThan: cutoffDate)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func cleanupLeastRecentlyUsed(keepCount: Int = 200) {
        repository.getAllCaches()
            .map { caches in
                caches.sorted { $0.lastAccessDate > $1.lastAccessDate }
                    .dropFirst(keepCount)
            }
            .flatMap { [weak self] oldCaches -> Observable<Void> in
                guard let self = self else { return Observable.just(()) }

                return Observable.from(oldCaches.map { $0.imageKey })
                    .flatMap { self.repository.deleteColorCache(forImageKey: $0) }
                    .toArray()
                    .asObservable()
                    .map { _ in () }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    // MARK: - Statistics

    private func incrementMemoryHit() {
        statsQueue.async(flags: .barrier) { [weak self] in
            self?.memoryHitCount += 1
        }
    }

    private func incrementPersistentHit() {
        statsQueue.async(flags: .barrier) { [weak self] in
            self?.persistentHitCount += 1
        }
    }

    private func incrementMiss() {
        statsQueue.async(flags: .barrier) { [weak self] in
            self?.missCount += 1
        }
    }

    func getStatistics() -> DominantColorCacheStats {
        return statsQueue.sync {
            let totalRequests = memoryHitCount + persistentHitCount + missCount
            let memoryHitRate = totalRequests > 0 ? Double(memoryHitCount) / Double(totalRequests) : 0.0
            let persistentHitRate = totalRequests > 0 ? Double(persistentHitCount) / Double(totalRequests) : 0.0
            let missRate = totalRequests > 0 ? Double(missCount) / Double(totalRequests) : 0.0

            return DominantColorCacheStats(
                memoryHitCount: memoryHitCount,
                persistentHitCount: persistentHitCount,
                missCount: missCount,
                totalRequests: totalRequests,
                memoryHitRate: memoryHitRate,
                persistentHitRate: persistentHitRate,
                missRate: missRate
            )
        }
    }

    func resetStatistics() {
        statsQueue.async(flags: .barrier) { [weak self] in
            self?.memoryHitCount = 0
            self?.persistentHitCount = 0
            self?.missCount = 0
        }
    }

    func printStatistics() {
        let stats = getStatistics()
        print("""

        📊 [ColorCache Statistics]
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Total Requests: \(stats.totalRequests)

        Memory Cache:
          - Hits: \(stats.memoryHitCount)
          - Rate: \(String(format: "%.1f%%", stats.memoryHitRate * 100))

        Persistent Cache:
          - Hits: \(stats.persistentHitCount)
          - Rate: \(String(format: "%.1f%%", stats.persistentHitRate * 100))

        Extraction:
          - Count: \(stats.missCount)
          - Rate: \(String(format: "%.1f%%", stats.missRate * 100))
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }
}

// MARK: - Statistics Model

struct DominantColorCacheStats {
    let memoryHitCount: Int
    let persistentHitCount: Int
    let missCount: Int
    let totalRequests: Int
    let memoryHitRate: Double
    let persistentHitRate: Double
    let missRate: Double
}
