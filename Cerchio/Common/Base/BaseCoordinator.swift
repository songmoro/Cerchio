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
        if let baseCoordinator = coordinator as? BaseCoordinator {
            baseCoordinator.parentCoordinator = self
        }
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

    // MARK: - Navigation Helpers
    func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }

    func present(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.present(viewController, animated: animated)
    }

    func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    func dismiss(animated: Bool = true) {
        navigationController.dismiss(animated: animated)
    }

    // MARK: - Coordinator Helpers
    func presentCoordinator(_ coordinator: BaseCoordinator, animated: Bool = true) {
        let presentedNav = UINavigationController()
        coordinator.navigationController = presentedNav
        addChildCoordinator(coordinator)
        coordinator.start()
        navigationController.present(presentedNav, animated: animated)
    }

    deinit {
        print("\(String(describing: type(of: self))) deinit")
    }
}
