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

        let activeSession = TimerSessionManager.shared.getActiveSession()
        var hasActiveActivity = false

        if #available(iOS 16.2, *) {
            hasActiveActivity = !LiveActivityManager.shared.getActiveActivities().isEmpty
        }

        if let session = activeSession {
            cleanupInactiveNotifications(activeSessionId: session.sessionId)

            let remaining: Int

            if let pausedAt = session.pausedAt {
                remaining = max(0, Int(session.targetEndTime.timeIntervalSince(pausedAt)))
            } else {
                remaining = max(0, Int(session.targetEndTime.timeIntervalSince(Date())))
            }

            let isCompleted = remaining <= 0

            if isCompleted {
                if #available(iOS 16.2, *) {
                    _ = LiveActivityManager.shared.endAllActivities()
                        .subscribe(onNext: { [weak self] in
                            self?.showSessionRecoveryDialog(session)
                        })
                } else {
                    showSessionRecoveryDialog(session)
                }
            } else if hasActiveActivity {
                restoreSession(session, reason: "정상 복구")
            } else {
                showSessionRecoveryDialog(session)
            }
            
            return
        }

        if hasActiveActivity {
            if #available(iOS 16.2, *) {
                _ = LiveActivityManager.shared.endAllActivities().subscribe()
            }
            cleanupInactiveNotifications(activeSessionId: nil)
            return
        }

        cleanupInactiveNotifications(activeSessionId: nil)
    }

    private func cleanupInactiveNotifications(activeSessionId: String?) {
        NotificationManager.shared.removeInactiveTimerNotifications(activeSessionId: activeSessionId)
            .subscribe(onNext: {
                
            }, onError: { error in
                print("[AppCoordinator]  Failed to cleanup notifications: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func restoreSession(_ session: TimerSessionManager.ActiveSession, reason: String) {
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        _ = bookRepository.getBook(by: session.bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] realmBook in
                guard let self = self, let realmBook = realmBook else {
                    TimerSessionManager.shared.clearActiveSession()
                    return
                }

                let book = realmBook.toBook()
                self.navigateToTimerScreen(book: book, session: session)
            }, onError: { error in
                print("[AppCoordinator]  Error loading book: \(error)")
                TimerSessionManager.shared.clearActiveSession()
            })
    }

    private func showSessionRecoveryDialog(_ session: TimerSessionManager.ActiveSession) {
        let targetSeconds = session.targetMinutes * 60
        let remaining: Int

        if let pausedAt = session.pausedAt {
            remaining = max(0, Int(session.targetEndTime.timeIntervalSince(pausedAt)))
        } else {
            remaining = max(0, Int(session.targetEndTime.timeIntervalSince(Date())))
        }

        let displayedElapsedSeconds = targetSeconds - remaining
        
        let minutes = displayedElapsedSeconds / 60
        let seconds = displayedElapsedSeconds % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)

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
        _ = dependencies.serviceFactory.createReadingSessionRepository()

        TimerSessionManager.shared.clearActiveSession()
    }

    private func navigateToTimerScreen(book: Book, session: TimerSessionManager.ActiveSession) {
        let bookDetailCoordinator = BookDetailCoordinator(navigationController: navigationController)
        bookDetailCoordinator.setupDependencies(serviceFactory: dependencies.serviceFactory, book: book)
        addChildCoordinator(bookDetailCoordinator)

        let bookDetailViewController = BookDetailViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let service = BookDetailService(serviceFactory: dependencies.serviceFactory)
        let bookDetailReactor = BookDetailReactor(book: book, bookRepository: bookRepository, service: service)
        bookDetailViewController.coordinator = bookDetailCoordinator
        bookDetailViewController.reactor = bookDetailReactor

        let timerCoordinator = ReadingTimerCoordinator(
            navigationController: navigationController,
            serviceFactory: dependencies.serviceFactory,
            bookId: book.id,
            bookTitle: book.title,
            session: session
        )
        bookDetailCoordinator.addChildCoordinator(timerCoordinator)

        timerCoordinator.completion
            .take(1)
            .subscribe(onNext: { [weak bookDetailCoordinator] in
                if let coordinator = bookDetailCoordinator?.childCoordinators.first(where: { $0 is ReadingTimerCoordinator }) {
                    bookDetailCoordinator?.removeChildCoordinator(coordinator)
                }
            })
            .disposed(by: disposeBag)

        let readingTimerViewController = timerCoordinator.createViewController()

        navigationController.setViewControllers([
            navigationController.viewControllers.first!,
            bookDetailViewController,
            readingTimerViewController
        ], animated: false)
    }
}
