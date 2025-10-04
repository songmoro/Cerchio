//
//  NotificationRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 10/4/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol NotificationRepositoryProtocol {
    func getAllNotifications() -> Observable<[RealmNotification]>
    func getNotificationById(_ id: String) -> Observable<RealmNotification?>
    func getNotificationsByStatus(_ status: AppNotification.NotificationStatus) -> Observable<[RealmNotification]>
    func getNotificationsByType(_ type: AppNotification.NotificationType) -> Observable<[RealmNotification]>
    func getUnreadNotifications() -> Observable<[RealmNotification]>
    func getUnreadCount() -> Observable<Int>
    func saveNotification(_ notification: RealmNotification) -> Observable<RealmNotification>
    func updateNotificationStatus(_ notificationId: String, status: AppNotification.NotificationStatus) -> Observable<RealmNotification>
    func markAsDelivered(_ notificationId: String) -> Observable<RealmNotification>
    func markAsDismissed(_ notificationId: String) -> Observable<RealmNotification>
    func cancelNotification(_ notificationId: String) -> Observable<Void>
    func deleteNotification(_ notification: RealmNotification) -> Observable<Void>
    func deleteExpiredNotifications(olderThan date: Date) -> Observable<Void>
}

final class NotificationRepository: BaseRepository<RealmNotification>, NotificationRepositoryProtocol {

    func getAllNotifications() -> Observable<[RealmNotification]> {
        return sorted(by: "createdAt", ascending: false)
    }

    func getNotificationById(_ id: String) -> Observable<RealmNotification?> {
        return performOnMainThread {
            return self.realm.object(ofType: RealmNotification.self, forPrimaryKey: id)
        }
    }

    func getNotificationsByStatus(_ status: AppNotification.NotificationStatus) -> Observable<[RealmNotification]> {
        return filterAndSort(
            "status == %@",
            sortBy: "scheduledDate",
            ascending: false,
            status.rawValue
        )
    }

    func getNotificationsByType(_ type: AppNotification.NotificationType) -> Observable<[RealmNotification]> {
        return filterAndSort(
            "type == %@",
            sortBy: "scheduledDate",
            ascending: false,
            type.rawValue
        )
    }

    func getUnreadNotifications() -> Observable<[RealmNotification]> {
        return filterAndSort(
            "status == %@ OR status == %@",
            sortBy: "scheduledDate",
            ascending: false,
            AppNotification.NotificationStatus.scheduled.rawValue,
            AppNotification.NotificationStatus.delivered.rawValue
        )
    }

    func getUnreadCount() -> Observable<Int> {
        return performOnMainThread {
            let scheduledCount = self.realm.objects(RealmNotification.self)
                .filter("status == %@", AppNotification.NotificationStatus.scheduled.rawValue)
                .count
            let deliveredCount = self.realm.objects(RealmNotification.self)
                .filter("status == %@", AppNotification.NotificationStatus.delivered.rawValue)
                .count
            return scheduledCount + deliveredCount
        }
    }

    func saveNotification(_ notification: RealmNotification) -> Observable<RealmNotification> {
        return save(notification)
    }

    func updateNotificationStatus(_ notificationId: String, status: AppNotification.NotificationStatus) -> Observable<RealmNotification> {
        return performWriteTransaction {
            guard let notification = self.realm.object(ofType: RealmNotification.self, forPrimaryKey: notificationId) else {
                throw RepositoryError.objectNotFound
            }

            notification.status = status.rawValue

            switch status {
            case .delivered:
                notification.deliveredDate = Date()
            case .dismissed:
                notification.dismissedDate = Date()
            default:
                break
            }

            return notification
        }
    }

    func markAsDelivered(_ notificationId: String) -> Observable<RealmNotification> {
        return updateNotificationStatus(notificationId, status: .delivered)
    }

    func markAsDismissed(_ notificationId: String) -> Observable<RealmNotification> {
        return updateNotificationStatus(notificationId, status: .dismissed)
    }

    func cancelNotification(_ notificationId: String) -> Observable<Void> {
        return updateNotificationStatus(notificationId, status: .cancelled)
            .map { _ in () }
    }

    func deleteNotification(_ notification: RealmNotification) -> Observable<Void> {
        return delete(notification)
    }

    func deleteExpiredNotifications(olderThan date: Date) -> Observable<Void> {
        return performWriteTransaction {
            let expiredNotifications = self.realm.objects(RealmNotification.self)
                .filter("scheduledDate < %@ AND (status == %@ OR status == %@)",
                        date,
                        AppNotification.NotificationStatus.dismissed.rawValue,
                        AppNotification.NotificationStatus.cancelled.rawValue)
            self.realm.delete(expiredNotifications)
            return ()
        }
    }
}
