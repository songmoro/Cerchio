//
//  DependencyContainer.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

protocol DependencyContainerProtocol {
    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T)
    func register<T>(_ serviceType: T.Type, instance: T)
    func resolve<T>(_ serviceType: T.Type) -> T?
    func resolve<T>(_ serviceType: T.Type) -> T
}

final class DependencyContainer: DependencyContainerProtocol {
    private var services: [String: Any] = [:]
    private let queue = DispatchQueue(label: "dependencyContainer.queue", attributes: .concurrent)

    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T) {
        let key = String(describing: serviceType)
        queue.async(flags: .barrier) {
            self.services[key] = factory
        }
    }

    func register<T>(_ serviceType: T.Type, instance: T) {
        let key = String(describing: serviceType)
        queue.async(flags: .barrier) {
            self.services[key] = instance
        }
    }

    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)

        return queue.sync {
            if let factory = services[key] as? () -> T {
                return factory()
            } else if let instance = services[key] as? T {
                return instance
            }
            return nil
        }
    }

    func resolve<T>(_ serviceType: T.Type) -> T {
        guard let service: T = resolve(serviceType) else {
            fatalError("Service \(serviceType) not registered")
        }
        return service
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
        }
    }
}

protocol DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol)
}

struct NetworkAssembly: DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol) {
        container.register(NetworkClientProtocol.self) {
            URLSessionNetworkClient()
        }

        container.register(ServiceDependencies.self) {
            DefaultServiceDependencies()
        }

        container.register(ServiceFactory.self) { [container] in
            let dependencies: ServiceDependencies = container.resolve(ServiceDependencies.self)
            return ServiceFactory(dependencies: dependencies)
        }
    }
}

struct RepositoryAssembly: DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol) {
    }
}

final class DependencyAssembler {
    private let container: DependencyContainer
    private let assemblies: [DependencyAssemblyProtocol]

    init(assemblies: [DependencyAssemblyProtocol] = [
        NetworkAssembly(),
        RepositoryAssembly()
    ]) {
        self.container = DependencyContainer()
        self.assemblies = assemblies
        setupDependencies()
    }

    private func setupDependencies() {
        assemblies.forEach { assembly in
            assembly.assemble(container: container)
        }
    }

    func resolve<T>(_ serviceType: T.Type) -> T {
        return container.resolve(serviceType)
    }

    func resolve<T>(_ serviceType: T.Type) -> T? {
        return container.resolve(serviceType)
    }
}
