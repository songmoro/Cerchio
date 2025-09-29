//
//  ServiceFactory.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

// MARK: - Service Factory Protocol
protocol ServiceFactoryProtocol {
    associatedtype Dependencies

    var dependencies: Dependencies { get }

    init(dependencies: Dependencies)
}

// MARK: - Base Service Factory
class BaseServiceFactory<Dependencies>: ServiceFactoryProtocol {
    let dependencies: Dependencies

    required init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

// MARK: - Main Service Factory
final class ServiceFactory: BaseServiceFactory<ServiceDependencies> {

    // MARK: - Service Cache
    private var serviceCache: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "serviceFactory.cache", attributes: .concurrent)

    required init(dependencies: ServiceDependencies) {
        super.init(dependencies: dependencies)
    }

    // MARK: - Generic Service Creation
    func createService<T: ServiceProtocol>(_ serviceType: T.Type) -> T where T.Dependencies == ServiceDependencies {
        let key = String(describing: serviceType)

        return cacheQueue.sync {
            if let cached = serviceCache[key] as? T {
                return cached
            }

            let service = serviceType.init(dependencies: dependencies)

            cacheQueue.async(flags: .barrier) {
                self.serviceCache[key] = service
            }

            return service
        }
    }

    // MARK: - Service Creation Methods

    /// Creates a BookSearchService instance
    func createBookSearchService() -> BookSearchServiceProtocol {
        let serviceDependencies = BookSearchService.Dependencies(networkClient: dependencies.networkClient)
        return BookSearchService(dependencies: serviceDependencies)
    }

    /// Creates a Mock BookSearchService instance for testing
    func createMockBookSearchService(scenario: MockBookSearchService.MockScenario = .success) -> BookSearchServiceProtocol {
        return MockBookSearchService(scenario: scenario)
    }

    // MARK: - Cache Management
    func clearServiceCache() {
        cacheQueue.async(flags: .barrier) {
            self.serviceCache.removeAll()
        }
    }

    func removeServiceFromCache<T: ServiceProtocol>(_ serviceType: T.Type) {
        let key = String(describing: serviceType)
        cacheQueue.async(flags: .barrier) {
            self.serviceCache.removeValue(forKey: key)
        }
    }
}

// MARK: - Factory Builder Protocol
protocol FactoryBuilderProtocol {
    static func build() -> ServiceFactory
    static func buildWithCustomDependencies(_ dependencies: ServiceDependencies) -> ServiceFactory
}

// MARK: - Factory Builder Implementation
extension ServiceFactory: FactoryBuilderProtocol {
    static func build() -> ServiceFactory {
        return ServiceFactory(dependencies: DefaultServiceDependencies())
    }

    static func buildWithCustomDependencies(_ dependencies: ServiceDependencies) -> ServiceFactory {
        return ServiceFactory(dependencies: dependencies)
    }
}



// MARK: - Environment-based Factory
enum Environment {
    case development
    case staging
    case production
    case testing
}

extension ServiceFactory {
    static func build(for environment: Environment) -> ServiceFactory {
        let dependencies: ServiceDependencies

        switch environment {
        case .development:
            dependencies = DevelopmentServiceDependencies()
        case .staging:
            dependencies = StagingServiceDependencies()
        case .production:
            dependencies = ProductionServiceDependencies()
        case .testing:
            dependencies = TestingServiceDependencies()
        }

        return ServiceFactory(dependencies: dependencies)
    }
}

// MARK: - Environment-specific Dependencies
struct DevelopmentServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol = URLSessionNetworkClient()
}

struct StagingServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol = URLSessionNetworkClient()
}

struct ProductionServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol = URLSessionNetworkClient()
}

struct TestingServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol = MockNetworkClient()
}

// MARK: - Mock Network Client for Testing
final class MockNetworkClient: NetworkClientProtocol {
    func execute<T: NetworkRequest>(_ request: T) -> Observable<T.Response> {
        // Mock implementation for testing
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }

    func execute<T: NetworkRequest>(_ request: T) -> Observable<APIResponse<T.Response>> {
        // Mock implementation for testing
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }

    func executePaginated<T: NetworkRequest>(_ request: T) -> Observable<PaginatedResponse<T.Response>> {
        // Mock implementation for testing
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }
}