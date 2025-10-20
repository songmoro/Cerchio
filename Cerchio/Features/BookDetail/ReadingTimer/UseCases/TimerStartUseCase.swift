//
//  TimerStartUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import UserNotifications

/// 유즈케이스: 타이머 시작
/// 1. 중복 세션 확인
/// 2. 알림 권한 확인 (없으면 요청)
/// 3. Live Activity 권한 확인
/// 4. 타이머 시작 (상태 변경 + 틱 시작)
/// 5. 알림 스케줄
/// 6. Live Activity 시작
/// 7. 세션 저장
final class TimerStartUseCase {
    // MARK: - Types
    enum StartError: Error {
        case duplicateSessionExists(TimerSessionManager.ActiveSession)
        case validationFailed(TimerValidationService.ValidationError)
    }

    struct StartResult {
        let sessionId: String
        let startTime: Date
        let needsUserConfirmation: TimerValidationService.ValidationError?
    }

    // MARK: - Properties
    private let validationService: TimerValidationService
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager
    private let stateManager: TimerStateManager

    // MARK: - Initialization
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

    // MARK: - Execute
    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int
    ) -> Observable<StartResult> {
        print("[TimerStartUseCase]  Starting timer flow...")

        // 1. 중복 세션 확인
        if let duplicate = validationService.checkDuplicateSession() {
            print("[TimerStartUseCase]  Duplicate session found")
            return .error(StartError.duplicateSessionExists(duplicate))
        }

        // 2. 권한 검증
        return validationService.validatePermissions()
            .flatMap { [weak self] validationResult -> Observable<StartResult> in
                guard let self = self else { return .empty() }

                self.validationService.logValidationResult(validationResult)

                // 권한 처리
                return self.handlePermissions(
                    validationResult: validationResult,
                    sessionId: sessionId,
                    bookId: bookId,
                    bookTitle: bookTitle,
                    targetMinutes: targetMinutes
                )
            }
    }

    // MARK: - Private

    private func handlePermissions(
        validationResult: TimerValidationService.ValidationResult,
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int
    ) -> Observable<StartResult> {
        switch validationResult.notificationStatus {
        case .notDetermined:
            // 알림 권한 요청
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
                        // 알림 거부 - 사용자 확인 필요
                        return .just(StartResult(
                            sessionId: sessionId,
                            startTime: Date(),
                            needsUserConfirmation: .notificationPermissionDenied
                        ))
                    }
                }

        case .authorized, .provisional:
            // 권한 있음 - 바로 시작
            return startTimer(
                sessionId: sessionId,
                bookId: bookId,
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                liveActivityEnabled: validationResult.liveActivityEnabled
            )

        case .denied, .ephemeral:
            // 알림 거부 - 사용자 확인 필요
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

        print("[TimerStartUseCase]  Starting timer")
        print("  - sessionId: \(sessionId)")
        print("  - startTime: \(startTime)")
        print("  - targetEndTime: \(targetEndTime)")

        // 1. 상태 업데이트
        stateManager.setState(.running)
        stateManager.setTargetEndTime(targetEndTime)
        stateManager.setPausedAt(nil)

        // 2. 알림 스케줄 (절대 시간)
        _ = notificationManager.scheduleAt(
            targetEndTime: targetEndTime,
            sessionId: sessionId,
            bookTitle: bookTitle
        )
        .subscribe(
            onNext: { notificationId in
                print("[TimerStartUseCase]  Notification scheduled: \(notificationId)")
            },
            onError: { error in
                print("[TimerStartUseCase]  Notification scheduling failed: \(error)")
            }
        )

        // 3. Live Activity 시작
        if #available(iOS 16.2, *), liveActivityEnabled {
            _ = activityManager.start(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: startTime,
                targetEndTime: targetEndTime
            )
            .subscribe(
                onNext: {
                    print("[TimerStartUseCase]  Live Activity started successfully")
                },
                onError: { error in
                    print("[TimerStartUseCase]  Live Activity failed to start: \(error)")
                }
            )
        } else {
            print("[TimerStartUseCase]  Live Activity not started - iOS version or permission issue")
        }

        // 4. 세션 저장
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
