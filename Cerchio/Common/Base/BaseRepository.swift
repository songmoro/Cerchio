//
//  BaseRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol RepositoryProtocol {
    associatedtype Entity: Object
    func create(_ entity: Entity) -> Observable<Void>
    func read() -> Observable<[Entity]>
    func update(_ entity: Entity) -> Observable<Void>
    func delete(_ entity: Entity) -> Observable<Void>
}

class BaseRepository<T: Object>: RepositoryProtocol {
    typealias Entity = T

    private let realm: Realm

    init() throws {
        self.realm = try Realm()
    }

    func create(_ entity: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.add(entity)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func read() -> Observable<[T]> {
        return Observable.create { observer in
            let objects = Array(self.realm.objects(T.self))
            observer.onNext(objects)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func update(_ entity: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.add(entity, update: .modified)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func delete(_ entity: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.realm.write {
                    self.realm.delete(entity)
                }
                observer.onNext(())
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
}