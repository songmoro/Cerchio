//
//  Notification.swift
//  Cerchio
//
//  Created by 송재훈 on 10/4/25.
//

import Foundation
import RealmSwift

nonisolated struct AppNotification: Hashable, Sendable {
    let id: String
    let type: NotificationType
    let status: NotificationStatus
    let scheduledDate: Date
    let deliveredDate: Date?
    let dismissedDate: Date?
    let relatedEntityId: String?
    let relatedEntityType: String?
    let title: String
    let body: String
    let badge: Int
    let createdAt: Date

    enum NotificationType: String, Codable, Sendable {
        case timerCompletion
        case dailyReminder
        case goalAchievement
        case readingStreak
        case bookRecommendation
    }

    enum NotificationStatus: String, Codable, Sendable {
        case scheduled
        case delivered
        case dismissed
        case cancelled
        case expired
    }

    enum EntityType: String, Codable, Sendable {
        case book
        case session
        case quote
        case goal
    }
}

final class RealmNotification: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var type: String
    @Persisted var status: String
    @Persisted var scheduledDate: Date
    @Persisted var deliveredDate: Date?
    @Persisted var dismissedDate: Date?
    @Persisted var relatedEntityId: String?
    @Persisted var relatedEntityType: String?
    @Persisted var title: String
    @Persisted var body: String
    @Persisted var badge: Int
    @Persisted var createdAt: Date

    convenience init(
        id: String = UUID().uuidString,
        type: AppNotification.NotificationType,
        status: AppNotification.NotificationStatus = .scheduled,
        scheduledDate: Date,
        relatedEntityId: String? = nil,
        relatedEntityType: AppNotification.EntityType? = nil,
        title: String,
        body: String,
        badge: Int = 1
    ) {
        self.init()
        self.id = id
        self.type = type.rawValue
        self.status = status.rawValue
        self.scheduledDate = scheduledDate
        self.relatedEntityId = relatedEntityId
        self.relatedEntityType = relatedEntityType?.rawValue
        self.title = title
        self.body = body
        self.badge = badge
        self.createdAt = Date()
    }

    func toAppNotification() -> AppNotification {
        return AppNotification(
            id: id,
            type: AppNotification.NotificationType(rawValue: type) ?? .timerCompletion,
            status: AppNotification.NotificationStatus(rawValue: status) ?? .scheduled,
            scheduledDate: scheduledDate,
            deliveredDate: deliveredDate,
            dismissedDate: dismissedDate,
            relatedEntityId: relatedEntityId,
            relatedEntityType: relatedEntityType,
            title: title,
            body: body,
            badge: badge,
            createdAt: createdAt
        )
    }
}
