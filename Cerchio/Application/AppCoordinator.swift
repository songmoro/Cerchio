//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift

struct AppDependencies {
    let dependencyAssembler: DependencyAssembler
    let serviceFactory: ServiceFactory

    init() {
        self.dependencyAssembler = DependencyAssembler()
        self.serviceFactory = dependencyAssembler.resolve(ServiceFactory.self)
    }
}

final class AppCoordinator: BaseCoordinator {
    private let window: UIWindow
    private let dependencies: AppDependencies

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        self.dependencies = AppDependencies()
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        showTabBar()

        // TabBar가 표시된 후 세션 복원
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkAndRestoreActiveTimerSession()
        }
    }

    private func showTabBar() {
        let tabBarDependencies = TabBarDependencies(
            serviceFactory: dependencies.serviceFactory
        )
        let tabBarCoordinator = TabBarCoordinator(navigationController: navigationController)
        addChildCoordinator(tabBarCoordinator)

        tabBarCoordinator.start(with: tabBarDependencies)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    private func checkAndRestoreActiveTimerSession() {
        print("[AppCoordinator] 🔍 Checking for active timer session...")

        let activeSession = TimerSessionManager.shared.getActiveSession()
        var hasActiveActivity = false

        // 라이브 액티비티 체크
        if #available(iOS 16.2, *) {
            hasActiveActivity = !LiveActivityManager.shared.getActiveActivities().isEmpty
            print("[AppCoordinator] 📱 Active Live Activities: \(hasActiveActivity)")
        }

        // 케이스 1: 세션도 있고 액티비티도 있음 → 정상 복구
        if let session = activeSession, hasActiveActivity {
            print("[AppCoordinator] ✅ Found active session with Live Activity")
            cleanupInactiveNotifications(activeSessionId: session.sessionId)
            restoreSession(session, reason: "정상 복구")
            return
        }

        // 케이스 2: 세션은 있는데 액티비티 없음 → 시스템 재부팅 또는 액티비티 종료
        if let session = activeSession, !hasActiveActivity {
            print("[AppCoordinator] ⚠️ Found session but no Live Activity (possible reboot)")
            cleanupInactiveNotifications(activeSessionId: session.sessionId)
            showSessionRecoveryDialog(session)
            return
        }

        // 케이스 3: 세션 없고 액티비티 있음 → 데이터 불일치 (액티비티만 정리)
        if activeSession == nil, hasActiveActivity {
            print("[AppCoordinator] ⚠️ Found Live Activity but no session (data mismatch)")
            if #available(iOS 16.2, *) {
                _ = LiveActivityManager.shared.endActivity()
            }
            cleanupInactiveNotifications(activeSessionId: nil)
            return
        }

        // 케이스 4: 둘 다 없음 → 정상
        print("[AppCoordinator] ✅ No active timer session to restore")
        cleanupInactiveNotifications(activeSessionId: nil)
    }

    private func cleanupInactiveNotifications(activeSessionId: String?) {
        NotificationManager.shared.removeInactiveTimerNotifications(activeSessionId: activeSessionId)
            .subscribe(onNext: {
                print("[AppCoordinator] 🧹 Inactive timer notifications cleaned up")
            }, onError: { error in
                print("[AppCoordinator] ⚠️ Failed to cleanup notifications: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func restoreSession(_ session: TimerSessionManager.ActiveSession, reason: String) {
        print("[AppCoordinator] 🔄 Restoring session - \(reason)")
        print("[AppCoordinator]   - sessionId: \(session.sessionId)")
        print("[AppCoordinator]   - bookTitle: \(session.bookTitle)")
        print("[AppCoordinator]   - targetEndTime: \(session.targetEndTime)")

        let bookRepository = dependencies.serviceFactory.createBookRepository()
        _ = bookRepository.getBook(by: session.bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] realmBook in
                guard let self = self, let realmBook = realmBook else {
                    print("[AppCoordinator] ❌ Failed to find book for session")
                    TimerSessionManager.shared.clearActiveSession()
                    return
                }

                let book = realmBook.toBook()
                self.navigateToTimerScreen(book: book, session: session)
            }, onError: { error in
                print("[AppCoordinator] ❌ Error loading book: \(error)")
                TimerSessionManager.shared.clearActiveSession()
            })
    }

    private func showSessionRecoveryDialog(_ session: TimerSessionManager.ActiveSession) {
        // 경과 시간 계산 (종료 시간 기준)
        let targetSeconds = session.targetMinutes * 60
        let remaining: Int

        if let pausedAt = session.pausedAt {
            // 일시정지 상태: 일시정지 시점의 남은 시간
            remaining = max(0, Int(session.targetEndTime.timeIntervalSince(pausedAt)))
        } else {
            // 실행 중: 현재 남은 시간
            remaining = max(0, Int(session.targetEndTime.timeIntervalSince(Date())))
        }

        let displayedElapsedSeconds = targetSeconds - remaining
        print("[AppCoordinator] Session elapsed: \(displayedElapsedSeconds)s")

        let minutes = displayedElapsedSeconds / 60
        let seconds = displayedElapsedSeconds % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)

        // 최소 기록 시간 (58초 = 약 1분)
        let minimumSeconds = 58
        let canSave = displayedElapsedSeconds >= minimumSeconds

        let alert = UIAlertController(
            title: "진행 중이던 독서 기록이 있습니다",
            message: "\"\(session.bookTitle)\"\n마지막 기록 시간: \(timeString)\n\n계속하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "계속 읽기", style: .default) { [weak self] _ in
            self?.restoreSession(session, reason: "사용자 선택 - 계속 읽기")
        })

        // 1분 이상인 경우만 저장 옵션 제공
        if canSave {
            alert.addAction(UIAlertAction(title: "기록하고 종료", style: .default) { [weak self] _ in
                self?.saveAndTerminateSession(session)
            })
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            TimerSessionManager.shared.clearActiveSession()
        })

        DispatchQueue.main.async { [weak self] in
            self?.window.rootViewController?.present(alert, animated: true)
        }
    }

    private func saveAndTerminateSession(_ session: TimerSessionManager.ActiveSession) {
        print("[AppCoordinator] 💾 Saving and terminating session")

        // TODO: ReadingRecord 생성 및 저장
        let sessionRepository = dependencies.serviceFactory.createReadingSessionRepository()

        // 임시로 세션만 정리
        TimerSessionManager.shared.clearActiveSession()
        print("[AppCoordinator] ✅ Session terminated")
    }

    private func navigateToTimerScreen(book: Book, session: TimerSessionManager.ActiveSession) {
        // UI 작업이므로 메인 스레드 보장
        assert(Thread.isMainThread, "navigateToTimerScreen must be called on main thread")

        // BookDetail Coordinator 생성
        let bookDetailCoordinator = BookDetailCoordinator(navigationController: navigationController)
        bookDetailCoordinator.setupDependencies(serviceFactory: dependencies.serviceFactory, book: book)
        addChildCoordinator(bookDetailCoordinator)

        // BookDetail ViewController 생성
        let bookDetailViewController = BookDetailViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let service = BookDetailService(serviceFactory: dependencies.serviceFactory)
        let bookDetailReactor = BookDetailReactor(book: book, bookRepository: bookRepository, service: service)
        bookDetailViewController.coordinator = bookDetailCoordinator
        bookDetailViewController.reactor = bookDetailReactor

        // ReadingTimer Coordinator 생성 (세션 복원용)
        let timerCoordinator = ReadingTimerCoordinator(
            navigationController: navigationController,
            serviceFactory: dependencies.serviceFactory,
            bookId: book.id,
            bookTitle: book.title,
            session: session
        )
        bookDetailCoordinator.addChildCoordinator(timerCoordinator)

        // 타이머 완료 시 처리
        timerCoordinator.completion
            .take(1)
            .subscribe(onNext: { [weak bookDetailCoordinator] in
                if let coordinator = bookDetailCoordinator?.childCoordinators.first(where: { $0 is ReadingTimerCoordinator }) {
                    bookDetailCoordinator?.removeChildCoordinator(coordinator)
                }
            })
            .disposed(by: disposeBag)

        // 타이머 ViewController 생성
        let readingTimerViewController = timerCoordinator.createViewController()

        // 스택에 한 번에 설정 (화면 전환 없음)
        navigationController.setViewControllers([
            navigationController.viewControllers.first!, // TabBar
            bookDetailViewController,
            readingTimerViewController
        ], animated: false)

        print("[AppCoordinator] ✅ Navigated to timer screen without transition")
    }
}
