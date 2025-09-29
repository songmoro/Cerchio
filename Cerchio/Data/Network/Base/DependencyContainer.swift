//
//  DependencyContainer.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

// MARK: - Dependency Container Protocol
protocol DependencyContainerProtocol {
    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T)
    func register<T>(_ serviceType: T.Type, instance: T)
    func resolve<T>(_ serviceType: T.Type) -> T?
    func resolve<T>(_ serviceType: T.Type) -> T
}

// MARK: - Dependency Container
final class DependencyContainer: DependencyContainerProtocol {
    private var services: [String: Any] = [:]
    private let queue = DispatchQueue(label: "dependencyContainer.queue", attributes: .concurrent)

    // MARK: - Registration
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

    // MARK: - Resolution
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

    // MARK: - Clear
    func clear() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
        }
    }
}

// MARK: - Dependency Assembly Protocol
protocol DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol)
}

// MARK: - Network Assembly
struct NetworkAssembly: DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol) {
        // Register NetworkClient
        container.register(NetworkClientProtocol.self) {
            URLSessionNetworkClient()
        }

        // Register ServiceDependencies
        container.register(ServiceDependencies.self) {
            DefaultServiceDependencies()
        }

        // Register ServiceFactory
        container.register(ServiceFactory.self) { [container] in
            let dependencies: ServiceDependencies = container.resolve(ServiceDependencies.self)
            return ServiceFactory(dependencies: dependencies)
        }
    }
}

// MARK: - Repository Assembly
struct RepositoryAssembly: DependencyAssemblyProtocol {
    func assemble(container: DependencyContainerProtocol) {
        // Repository 관련 의존성들을 등록
        // 예: BookRepository 등
    }
}

// MARK: - Main Dependency Assembler
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