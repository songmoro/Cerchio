//
//  TimerStartUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import UserNotifications

final class TimerStartUseCase {
    enum StartError: Error {
        case duplicateSessionExists(TimerSessionManager.ActiveSession)
        case validationFailed(TimerValidationService.ValidationError)
    }

    struct StartResult {
        let sessionId: String
        let startTime: Date
        let needsUserConfirmation: TimerValidationService.ValidationError?
    }

    private let validationService: TimerValidationService
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager
    private let stateManager: TimerStateManager

    init(
        validationService: TimerValidationService,
        notificationManager: TimerNotificationManager,
        activityManager: TimerActivityManager,
        sessionManager: TimerSessionManager,
        stateManager: TimerStateManager
    ) {
        self.validationService = validationService
        self.notificationManager = notificationManager
        self.activityManager = activityManager
        self.sessionManager = sessionManager
        self.stateManager = stateManager
    }

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int
    ) -> Observable<StartResult> {

        if let duplicate = validationService.checkDuplicateSession() {
            return .error(StartError.duplicateSessionExists(duplicate))
        }

        return validationService.validatePermissions()
            .flatMap { [weak self] validationResult -> Observable<StartResult> in
                guard let self = self else { return .empty() }

                self.validationService.logValidationResult(validationResult)

                return self.handlePermissions(
                    validationResult: validationResult,
                    sessionId: sessionId,
                    bookId: bookId,
                    bookTitle: bookTitle,
                    targetMinutes: targetMinutes
                )
            }
    }

    private func handlePermissions(
        validationResult: TimerValidationService.ValidationResult,
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int
    ) -> Observable<StartResult> {
        switch validationResult.notificationStatus {
        case .notDetermined:
            return validationService.requestNotificationPermission()
                .flatMap { [weak self] granted -> Observable<StartResult> in
                    guard let self = self else { return .empty() }

                    if granted {
                        return self.startTimer(
                            sessionId: sessionId,
                            bookId: bookId,
                            bookTitle: bookTitle,
                            targetMinutes: targetMinutes,
                            liveActivityEnabled: validationResult.liveActivityEnabled
                        )
                    } else {
                        return .just(StartResult(
                            sessionId: sessionId,
                            startTime: Date(),
                            needsUserConfirmation: .notificationPermissionDenied
                        ))
                    }
                }

        case .authorized, .provisional:
            return startTimer(
                sessionId: sessionId,
                bookId: bookId,
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                liveActivityEnabled: validationResult.liveActivityEnabled
            )

        case .denied, .ephemeral:
            return .just(StartResult(
                sessionId: sessionId,
                startTime: Date(),
                needsUserConfirmation: .notificationPermissionDenied
            ))

        @unknown default:
            return .just(StartResult(
                sessionId: sessionId,
                startTime: Date(),
                needsUserConfirmation: .notificationPermissionDenied
            ))
        }
    }

    private func startTimer(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        liveActivityEnabled: Bool
    ) -> Observable<StartResult> {
        let startTime = Date()
        let targetSeconds = targetMinutes * 60
        let targetEndTime = startTime.addingTimeInterval(TimeInterval(targetSeconds))

        stateManager.setState(.running)
        stateManager.setTargetEndTime(targetEndTime)
        stateManager.setPausedAt(nil)

        _ = notificationManager.scheduleAt(
            targetEndTime: targetEndTime,
            sessionId: sessionId,
            bookTitle: bookTitle
        )
        .subscribe(
            onNext: { notificationId in
            },
            onError: { error in
                print("[TimerStartUseCase]  Notification scheduling failed: \(error)")
            }
        )

        if #available(iOS 16.2, *), liveActivityEnabled {
            _ = activityManager.start(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: startTime,
                targetEndTime: targetEndTime
            )
            .subscribe(
                onNext: {
                },
                onError: { error in
                    print("[TimerStartUseCase]  Live Activity failed to start: \(error)")
                }
            )
        } else {
        }

        sessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: startTime,
            targetEndTime: targetEndTime,
            pausedAt: nil,
            activityId: nil
        )

        let needsConfirmation: TimerValidationService.ValidationError? = liveActivityEnabled ? nil : .liveActivityNotEnabled

        return .just(StartResult(
            sessionId: sessionId,
            startTime: startTime,
            needsUserConfirmation: needsConfirmation
        ))
    }
}
