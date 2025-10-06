//
//  TimerValidationService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import UserNotifications

/// 타이머 시작 전 권한 검증 및 유효성 확인 서비스
final class TimerValidationService {

    // MARK: - Types

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

    // MARK: - Properties

    private let notificationManager: NotificationManager
    private let sessionManager: TimerSessionManager

    // MARK: - Initialization

    init(
        notificationManager: NotificationManager = .shared,
        sessionManager: TimerSessionManager = .shared
    ) {
        self.notificationManager = notificationManager
        self.sessionManager = sessionManager
    }

    // MARK: - Validation

    /// 중복 세션 확인
    func checkDuplicateSession() -> TimerSessionManager.ActiveSession? {
        guard sessionManager.hasActiveSession() else { return nil }
        return sessionManager.getActiveSession()
    }

    /// 세션 저장 가능 여부 검증 (최소 시간)
    func canSaveSession(elapsedSeconds: Int, minimumSeconds: Int = 58) -> Bool {
        elapsedSeconds >= minimumSeconds
    }

    /// 알림 및 Live Activity 권한 검증
    func validatePermissions() -> Observable<ValidationResult> {
        // 1. 알림 권한 체크
        return notificationManager.checkAuthorizationStatus()
            .flatMap { [weak self] notificationStatus -> Observable<(UNAuthorizationStatus, Bool)> in
                guard let self = self else { return .empty() }

                // 2. Live Activity 권한 체크
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
                // 3. 결과 분석
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

    /// 알림 권한 요청
    func requestNotificationPermission() -> Observable<Bool> {
        return notificationManager.requestAuthorization()
    }

    // MARK: - Logging

    func logValidationResult(_ result: ValidationResult) {
        print("[TimerValidation] 🔍 Permission validation result:")
        print("  - isValid: \(result.isValid)")
        print("  - notificationStatus: \(result.notificationStatus)")
        print("  - liveActivityEnabled: \(result.liveActivityEnabled)")
        if let error = result.error {
            print("  - error: \(error)")
        }
    }
}
