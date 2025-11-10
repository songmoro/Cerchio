//
//  TimerValidationService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import UserNotifications

final class TimerValidationService {

    enum ValidationError: Error, Equatable {
        case notificationPermissionDenied
        case liveActivityNotEnabled
        case sessionTooShort
        case duplicateSessionExists
    }

    struct ValidationResult {
        let isValid: Bool
        let error: ValidationError?
        let notificationStatus: UNAuthorizationStatus
        let liveActivityEnabled: Bool
    }

    private let notificationManager: NotificationManager
    private let sessionManager: TimerSessionManager

    init(
        notificationManager: NotificationManager = .shared,
        sessionManager: TimerSessionManager = .shared
    ) {
        self.notificationManager = notificationManager
        self.sessionManager = sessionManager
    }

    func checkDuplicateSession() -> TimerSessionManager.ActiveSession? {
        guard sessionManager.hasActiveSession() else { return nil }
        return sessionManager.getActiveSession()
    }

    func canSaveSession(elapsedSeconds: Int, minimumSeconds: Int = 58) -> Bool {
        elapsedSeconds >= minimumSeconds
    }

    func validatePermissions() -> Observable<ValidationResult> {
        return notificationManager.checkAuthorizationStatus()
            .flatMap { notificationStatus -> Observable<(UNAuthorizationStatus, Bool)> in

                if #available(iOS 16.2, *) {
                    return LiveActivityManager.shared.checkActivityAuthorizationStatus()
                        .map { liveActivityEnabled in
                            (notificationStatus, liveActivityEnabled)
                        }
                } else {
                    return .just((notificationStatus, false))
                }
            }
            .map { (notificationStatus, liveActivityEnabled) -> ValidationResult in
                let error: ValidationError?

                switch notificationStatus {
                case .denied, .ephemeral:
                    error = .notificationPermissionDenied
                case .notDetermined, .authorized, .provisional:
                    if !liveActivityEnabled {
                        error = .liveActivityNotEnabled
                    } else {
                        error = nil
                    }
                @unknown default:
                    error = .notificationPermissionDenied
                }

                return ValidationResult(
                    isValid: error == nil,
                    error: error,
                    notificationStatus: notificationStatus,
                    liveActivityEnabled: liveActivityEnabled
                )
            }
    }

    func requestNotificationPermission() -> Observable<Bool> {
        return notificationManager.requestAuthorization()
    }

    func logValidationResult(_ result: ValidationResult) {
        if let error = result.error {
            print("  - error: \(error)")
        }
    }
}
