import Foundation
import RealmSwift
import UIKit

// MARK: - RealmColorCache (Persistent Model)

final class RealmColorCache: Object {
    @Persisted(primaryKey: true) var imageKey: String
    @Persisted var colorData: Data
    @Persisted var colorCount: Int
    @Persisted var lastAccessDate: Date
    @Persisted var createdAt: Date

    convenience init(imageKey: String, colors: [UIColor]) {
        self.init()
        self.imageKey = imageKey
        self.colorData = colors.toData() ?? Data()
        self.colorCount = colors.count
        self.lastAccessDate = Date()
        self.createdAt = Date()
    }

    func toColorCache() -> ColorCache? {
        guard let colors = [UIColor].fromData(colorData) else {
            return nil
        }

        return ColorCache(
            imageKey: imageKey,
            colors: colors,
            colorCount: colorCount,
            lastAccessDate: lastAccessDate,
            createdAt: createdAt
        )
    }
}

// MARK: - ColorCache (DTO)

struct ColorCache {
    let imageKey: String
    let colors: [UIColor]
    let colorCount: Int
    let lastAccessDate: Date
    let createdAt: Date

    func toRealmModel() -> RealmColorCache {
        let realm = RealmColorCache()
        realm.imageKey = imageKey
        realm.colorData = colors.toData() ?? Data()
        realm.colorCount = colorCount
        realm.lastAccessDate = lastAccessDate
        realm.createdAt = createdAt
        return realm
    }
}

// MARK: - Hashable Conformance

extension ColorCache: Hashable {
    static func == (lhs: ColorCache, rhs: ColorCache) -> Bool {
        return lhs.imageKey == rhs.imageKey &&
               lhs.colorCount == rhs.colorCount &&
               lhs.lastAccessDate == rhs.lastAccessDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(imageKey)
        hasher.combine(colorCount)
        hasher.combine(lastAccessDate)
    }
}
