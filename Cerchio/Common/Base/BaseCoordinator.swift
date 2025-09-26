//
//  BaseCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Coordinator Protocol
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    var parentCoordinator: Coordinator? { get set }

    func start()
    func childDidFinish(_ child: Coordinator)
    func finish()
}

// MARK: - Coordinatable Protocol
protocol Coordinatable: AnyObject {
    associatedtype Dependencies
    func start(with dependencies: Dependencies)
}

extension Coordinatable where Dependencies == Void {
    func start() { start(with: ()) }
}

// MARK: - Navigation Action
enum NavigationAction {
    case push
    case present
    case popToRoot
    case dismiss
}

// MARK: - Navigation Event Protocol
protocol NavigationEventProtocol {}

enum NavigationEvent: NavigationEventProtocol {
    case back
    case close
    case finished
}

// MARK: - Base Coordinator
class BaseCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: Coordinator?

    let navigationEvents = PublishRelay<NavigationEvent>()
    let disposeBag = DisposeBag()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func start() {
        fatalError("Must be overridden")
    }

    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }

    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }

    func childDidFinish(_ child: Coordinator) {
        removeChildCoordinator(child)
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
        childCoordinators.removeAll()
    }

    func navigate(to viewController: UIViewController, action: NavigationAction = .push, animated: Bool = true) {
        switch action {
        case .push:
            navigationController.pushViewController(viewController, animated: animated)
        case .present:
            navigationController.present(viewController, animated: animated)
        case .popToRoot:
            navigationController.popToRootViewController(animated: animated)
        case .dismiss:
            navigationController.dismiss(animated: animated)
        }
    }

    func presentCoordinator(_ coordinator: BaseCoordinator) {
        let presentedNav = UINavigationController()
        coordinator.navigationController = presentedNav
        addChildCoordinator(coordinator)
        coordinator.start()
        navigationController.present(presentedNav, animated: true)
    }

    func pushCoordinator(_ coordinator: BaseCoordinator) {
        coordinator.navigationController = navigationController
        addChildCoordinator(coordinator)
        coordinator.start()
    }

    deinit {
        print("✅ \(String(describing: type(of: self))) deinit")
    }
}