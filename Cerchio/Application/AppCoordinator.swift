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

        guard let activeSession = TimerSessionManager.shared.getActiveSession() else {
            print("[AppCoordinator] ❌ No active timer session to restore")
            return
        }

        print("[AppCoordinator] ✅ Found active timer session!")
        print("[AppCoordinator]   - sessionId: \(activeSession.sessionId)")
        print("[AppCoordinator]   - bookId: \(activeSession.bookId)")
        print("[AppCoordinator]   - bookTitle: \(activeSession.bookTitle)")
        print("[AppCoordinator]   - elapsedSeconds: \(activeSession.elapsedSeconds)")
        print("[AppCoordinator] 🔄 Restoring timer session...")

        // 도서 정보 조회
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        _ = bookRepository.getBook(by: activeSession.bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] realmBook in
                guard let self = self, let realmBook = realmBook else {
                    print("[AppCoordinator] ❌ Failed to find book for session")
                    TimerSessionManager.shared.clearActiveSession()
                    return
                }

                // RealmBook을 Book으로 변환
                let book = realmBook.toBook()

                // 타이머 화면으로 네비게이션
                self.navigateToTimerScreen(book: book, session: activeSession)
            }, onError: { error in
                print("[AppCoordinator] ❌ Error loading book: \(error)")
                TimerSessionManager.shared.clearActiveSession()
            })
    }

    private func navigateToTimerScreen(book: Book, session: TimerSessionManager.ActiveSession) {
        // BookDetail 화면을 먼저 push (애니메이션 없이)
        let bookDetailDependencies = BookDetailDependencies(
            serviceFactory: dependencies.serviceFactory,
            book: book
        )
        let bookDetailCoordinator = BookDetailCoordinator(navigationController: navigationController)
        addChildCoordinator(bookDetailCoordinator)
        bookDetailCoordinator.start(with: bookDetailDependencies)

        // 타이머 화면 즉시 push
        let readingTimerViewController = ReadingTimerViewController()
        let sessionRepository = dependencies.serviceFactory.createReadingSessionRepository()
        let readingTimerReactor = ReadingTimerReactor(
            session: session,
            sessionRepository: sessionRepository
        )

        readingTimerViewController.reactor = readingTimerReactor

        navigationController.pushViewController(readingTimerViewController, animated: false)
        print("[AppCoordinator] ✅ Navigated to timer screen")
    }
}
