//
//  ServiceFactory.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

protocol ServiceFactoryProtocol {
    associatedtype Dependencies

    var dependencies: Dependencies { get }

    init(dependencies: Dependencies)
}

class BaseServiceFactory<Dependencies>: ServiceFactoryProtocol {
    let dependencies: Dependencies

    required init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

final class ServiceFactory: BaseServiceFactory<ServiceDependencies> {

    private var serviceCache: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "serviceFactory.cache", attributes: .concurrent)

    required init(dependencies: ServiceDependencies) {
        super.init(dependencies: dependencies)
    }

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

    func createBookSearchService() -> BookSearchServiceProtocol {
        let serviceDependencies = BookSearchService.Dependencies(networkClient: dependencies.networkClient)
        return BookSearchService(dependencies: serviceDependencies)
    }

    func createMockBookSearchService(scenario: MockBookSearchService.MockScenario = .success) -> BookSearchServiceProtocol {
        return MockBookSearchService(scenario: scenario)
    }

    func createBookRepository() -> BookRepositoryProtocol {
        do {
            return try BookRepository()
        } catch {
            fatalError("Failed to create BookRepository: \(error)")
        }
    }

    func createQuoteRepository() -> QuoteRepositoryProtocol {
        do {
            return try QuoteRepository()
        } catch {
            fatalError("Failed to create QuoteRepository: \(error)")
        }
    }

    func createPhotoRepository() -> PhotoRepositoryProtocol {
        do {
            return try PhotoRepository()
        } catch {
            fatalError("Failed to create PhotoRepository: \(error)")
        }
    }

    func createTagRepository() -> TagRepositoryProtocol {
        do {
            return try TagRepository()
        } catch {
            fatalError("Failed to create TagRepository: \(error)")
        }
    }

    func createSearchHistoryRepository() -> SearchHistoryRepositoryProtocol {
        do {
            return try SearchHistoryRepository()
        } catch {
            fatalError("Failed to create SearchHistoryRepository: \(error)")
        }
    }

    func createReadingRecordRepository() -> ReadingRecordRepositoryProtocol {
        do {
            return try ReadingRecordRepository()
        } catch {
            fatalError("Failed to create ReadingRecordRepository: \(error)")
        }
    }

    func createReadingSessionRepository() -> ReadingSessionRepositoryProtocol {
        do {
            return try ReadingSessionRepository()
        } catch {
            fatalError("Failed to create ReadingSessionRepository: \(error)")
        }
    }

    func createDebugLogRepository() -> DebugLogRepositoryProtocol {
        do {
            return try DebugLogRepository()
        } catch {
            fatalError("Failed to create DebugLogRepository: \(error)")
        }
    }

    func createColorCacheRepository() -> ColorCacheRepositoryProtocol {
        do {
            return try ColorCacheRepository()
        } catch {
            fatalError("Failed to create ColorCacheRepository: \(error)")
        }
    }

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

protocol FactoryBuilderProtocol {
    static func build() -> ServiceFactory
    static func buildWithCustomDependencies(_ dependencies: ServiceDependencies) -> ServiceFactory
}

extension ServiceFactory: FactoryBuilderProtocol {
    static func build() -> ServiceFactory {
        return ServiceFactory(dependencies: DefaultServiceDependencies())
    }

    static func buildWithCustomDependencies(_ dependencies: ServiceDependencies) -> ServiceFactory {
        return ServiceFactory(dependencies: dependencies)
    }
}

enum Environment {
    case development
    case staging
    case production
    case testing

    static var current: Environment {
        #if DEBUG
        if let bundleId = Bundle.main.bundleIdentifier, bundleId.contains(".dev") {
            return .development
        }
        return .testing
        #else
        return .production
        #endif
    }
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

    static func buildForCurrentEnvironment() -> ServiceFactory {
        return build(for: .current)
    }
}

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

final class MockNetworkClient: NetworkClientProtocol {
    func execute<T: NetworkRequest>(_ request: T) -> Observable<T.Response> {
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }

    func execute<T: NetworkRequest>(_ request: T) -> Observable<APIResponse<T.Response>> {
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }

    func executePaginated<T: NetworkRequest>(_ request: T) -> Observable<PaginatedResponse<T.Response>> {
        return Observable.error(NetworkError.networkError(NSError(domain: "Mock", code: NetworkConstants.ErrorCode.mockImplementation, userInfo: [NSLocalizedDescriptionKey: "Mock implementation"])))
    }
}
