//
//  SearchResultCache.swift
//  Cerchio
//
//  Created by 송재훈 on 2025-11-12.
//

import Foundation

final class SearchResultCache {
    static let shared = SearchResultCache()

    private let cache: NSCache<NSString, CachedSearchResult>
    private let lock = NSLock()
    private let maxCacheCount = 10
    private let cacheTTL: TimeInterval = 1800

    private init() {
        self.cache = NSCache<NSString, CachedSearchResult>()
        self.cache.countLimit = maxCacheCount
    }

    func get(forKey key: String) -> CachedSearchResult? {
        lock.lock()
        defer { lock.unlock() }

        guard let cachedResult = cache.object(forKey: key as NSString) else {
            return nil
        }

        if cachedResult.isExpired(ttl: cacheTTL) {
            cache.removeObject(forKey: key as NSString)
            return nil
        }

        return cachedResult
    }

    func set(response: BookSearchResponse, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        let cachedResult = CachedSearchResult(response: response, cachedAt: Date())
        cache.setObject(cachedResult, forKey: key as NSString)
    }

    func remove(forKey: String) {
        lock.lock()
        defer { lock.unlock() }

        cache.removeObject(forKey: forKey as NSString)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }

        cache.removeAllObjects()
    }
}
