//
//  BaseCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol Coordinatable: AnyObject {
    associatedtype Dependencies
    func start(with dependencies: Dependencies)
}

extension Coordinatable where Dependencies == Void {
    func start() { start(with: ()) }
}

protocol NavigationEventProtocol {
    // Define common navigation events
}

class BaseCoordinator<NavigationEvent: NavigationEventProtocol>: NSObject, Coordinatable {
    typealias Dependencies = Void

    var childCoordinators: [BaseCoordinator] = []
    weak var parentCoordinator: BaseCoordinator?
    let navigationEvents = PublishRelay<NavigationEvent>()
    let disposeBag = DisposeBag()

    func start(with dependencies: Void) {
        // Override in subclasses
    }

    func addChildCoordinator<T: BaseCoordinator>(_ coordinator: T) {
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }

    func removeChildCoordinator<T: BaseCoordinator>(_ coordinator: T) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    func finish() {
        parentCoordinator?.removeChildCoordinator(self)
        childCoordinators.removeAll()
    }

    deinit {
        print("✅ \(String(describing: type(of: self))) deinit")
    }
}