//
//  SearchCacheModels.swift
//  Cerchio
//
//  Created by 송재훈 on 2025-11-12.
//

import Foundation

final class CachedSearchResult {
    let response: BookSearchResponse
    let cachedAt: Date

    init(response: BookSearchResponse, cachedAt: Date = Date()) {
        self.response = response
        self.cachedAt = cachedAt
    }

    func isExpired(ttl: TimeInterval = 1800) -> Bool {
        let elapsedTime = Date().timeIntervalSince(cachedAt)
        return elapsedTime > ttl
    }
}
