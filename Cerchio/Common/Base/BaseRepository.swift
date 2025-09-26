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

// MARK: - Base Repository
class BaseRepository<T: Object>: BaseRepositoryType {
    typealias Model = T

    let realm: Realm

    init() throws {
        self.realm = try Realm()
    }

    func fetch() -> Observable<[T]> {
        return Observable.create { observer in
            let results = self.realm.objects(T.self)
            observer.onNext(Array(results))
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func save(_ model: T) -> Observable<T> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.add(model)
                }
                observer.onNext(model)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func delete(_ model: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.delete(model)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func update(_ model: T) -> Observable<T> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.add(model, update: .modified)
                }
                observer.onNext(model)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func findById(_ id: String) -> Observable<T?> {
        return Observable.create { observer in
            let object = self.realm.object(ofType: T.self, forPrimaryKey: id)
            observer.onNext(object)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func create(_ entity: T) -> Observable<Void> {
        return save(entity).map { _ in () }
    }

    func read() -> Observable<[T]> {
        return fetch()
    }
}