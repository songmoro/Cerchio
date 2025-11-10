//
//  ServiceLayer.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

protocol ServiceProtocol {
    associatedtype Dependencies

    var networkClient: NetworkClientProtocol { get }

    init(dependencies: Dependencies)
}

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

protocol ServiceDependencies {
    var networkClient: NetworkClientProtocol { get }
}

struct DefaultServiceDependencies: ServiceDependencies {
    let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = URLSessionNetworkClient()) {
        self.networkClient = networkClient
    }
}

extension ServiceProtocol {
    func handleError<T>(_ error: Error) -> Observable<T> {
        print("Service Error: \(error)")

        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                break
            case .rateLimited:
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
