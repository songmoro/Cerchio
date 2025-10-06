//
//  BaseRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - Repository Type Protocol
protocol RepositoryType {
    associatedtype Model

    func fetch() -> Observable<[Model]>
    func save(_ model: Model) -> Observable<Model>
    func delete(_ model: Model) -> Observable<Void>
    func update(_ model: Model) -> Observable<Model>
}

// MARK: - Base Repository Type Protocol
protocol BaseRepositoryType: RepositoryType where Model: Object {
    var realm: Realm { get }
}

// MARK: - Base Repository Error
enum RepositoryError: Error {
    case realmInitializationFailed
    case objectNotFound
    case objectAlreadyDeleted
    case transactionFailed(Error)

    var localizedDescription: String {
        switch self {
        case .realmInitializationFailed:
            return "Failed to initialize Realm database"
        case .objectNotFound:
            return "Object not found in database"
        case .objectAlreadyDeleted:
            return "Object has already been deleted or invalidated"
        case .transactionFailed(let error):
            return "Database transaction failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Base Repository
class BaseRepository<T: Object>: BaseRepositoryType {
    typealias Model = T

    let realm: Realm

    init() throws {
        do {
            self.realm = try Realm()
        } catch {
            throw RepositoryError.realmInitializationFailed
        }
    }

    // MARK: - Basic CRUD Operations
    func fetch() -> Observable<[T]> {
        return performOnMainThread {
            Array(self.realm.objects(T.self))
        }
    }

    func save(_ model: T) -> Observable<T> {
        return performWriteTransaction {
            self.realm.add(model, update: .modified)
            return model
        }
    }

    func delete(_ model: T) -> Observable<Void> {
        return performWriteTransaction {
            // Check if object is still valid before deletion
            guard !model.isInvalidated else {
                throw RepositoryError.objectAlreadyDeleted
            }
            self.realm.delete(model)
            return ()
        }
    }

    func update(_ model: T) -> Observable<T> {
        return performWriteTransaction {
            self.realm.add(model, update: .modified)
            return model
        }
    }

    // MARK: - Query Operations
    func findById(_ id: String) -> Observable<T?> {
        return performOnMainThread {
            self.realm.object(ofType: T.self, forPrimaryKey: id)
        }
    }

    func filter(_ predicate: String, _ args: Any...) -> Observable<[T]> {
        return performOnMainThread {
            Array(self.realm.objects(T.self).filter(predicate, args))
        }
    }

    func sorted(by keyPath: String, ascending: Bool = true) -> Observable<[T]> {
        return performOnMainThread {
            Array(self.realm.objects(T.self).sorted(byKeyPath: keyPath, ascending: ascending))
        }
    }

    func filterAndSort(_ predicate: String, sortBy keyPath: String, ascending: Bool = true, _ args: Any...) -> Observable<[T]> {
        return performOnMainThread {
            Array(self.realm.objects(T.self)
                .filter(predicate, args)
                .sorted(byKeyPath: keyPath, ascending: ascending))
        }
    }

    // MARK: - Batch Operations
    func saveAll(_ models: [T]) -> Observable<[T]> {
        return performWriteTransaction {
            self.realm.add(models)
            return models
        }
    }

    func deleteAll(_ models: [T]) -> Observable<Void> {
        return performWriteTransaction {
            self.realm.delete(models)
            return ()
        }
    }

    func deleteAll() -> Observable<Void> {
        return performWriteTransaction {
            let objects = self.realm.objects(T.self)
            self.realm.delete(objects)
            return ()
        }
    }

    // MARK: - Helper Methods
    func performOnMainThread<U>(_ operation: @escaping () -> U) -> Observable<U> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                let result = operation()
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func performWriteTransaction<U>(_ operation: @escaping () throws -> U) -> Observable<U> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let result = try self.realm.write {
                        try operation()
                    }
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(RepositoryError.transactionFailed(error))
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - Legacy Support
    func create(_ entity: T) -> Observable<Void> {
        return save(entity).map { _ in () }
    }

    func read() -> Observable<[T]> {
        return fetch()
    }
}