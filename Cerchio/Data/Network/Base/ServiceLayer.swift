//
//  ServiceLayer.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

// MARK: - Service Protocol
protocol ServiceProtocol {
    associatedtype Dependencies

    var networkClient: NetworkClientProtocol { get }

    init(dependencies: Dependencies)
}

// MARK: - Base Service
class BaseService<Dependencies>: ServiceProtocol {
    let networkClient: NetworkClientProtocol

    required init(dependencies: Dependencies) {
        if let deps = dependencies as? ServiceDependencies {
            self.networkClient = deps.networkClient
        } else {
            fatalError("Dependencies must conform to ServiceDependencies")
        }
    }
}

// MARK: - Service Dependencies Protocol
protocol ServiceDependencies {
    var networkClient: NetworkClientProtocol { get }
}

// MARK: - Default Service Dependencies
struct DefaultServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = URLSessionNetworkClient()) {
        self.networkClient = networkClient
    }
}



// MARK: - Service Error Handling
extension ServiceProtocol {
    func handleError<T>(_ error: Error) -> Observable<T> {
        // Log error
        print("Service Error: \(error)")

        // Transform specific errors if needed
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                // Handle unauthorized access (e.g., redirect to login)
                break
            case .rateLimited:
                // Handle rate limiting (e.g., retry after delay)
                break
            default:
                break
            }
        }

        return Observable.error(error)
    }

    func retryWithDelay<T>(_ source: Observable<T>, retryCount: Int = NetworkConstants.Retry.defaultRetryCount, delay: TimeInterval = NetworkConstants.Retry.defaultRetryDelay) -> Observable<T> {
        return source
            .retry { errors in
                return errors
                    .enumerated()
                    .flatMap { (index, error) -> Observable<Int> in
                        if index < retryCount {
                            return Observable<Int>.timer(.seconds(Int(delay * Double(index + 1))), scheduler: MainScheduler.instance)
                        } else {
                            return Observable.error(error)
                        }
                    }
            }
    }
}
