//
//  QuoteListReactor.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import Foundation
import ReactorKit
import RxSwift
import RealmSwift

final class QuoteListReactor: Reactor {
    enum Action {
        case loadQuotes
        case deleteQuote(String) // ID로 삭제
    }

    enum Mutation {
        case setQuotes([Quote])
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var bookId: String
        var quotes: [Quote] = []
        var isLoading: Bool = false
        var error: Error?
    }

    let initialState: State

    init(bookId: String) {
        self.initialState = State(bookId: bookId)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadQuotes:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadQuotesFromRealm(),
                Observable.just(.setLoading(false))
            ])

        case .deleteQuote(let quoteId):
            return Observable.concat([
                Observable.just(.setLoading(true)),
                deleteQuoteFromRealm(quoteId),
                loadQuotesFromRealm(),
                Observable.just(.setLoading(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setQuotes(let quotes):
            newState.quotes = quotes

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error
        }

        return newState
    }

    private func loadQuotesFromRealm() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            do {
                let realm = try Realm()
                let realmQuotes = realm.objects(RealmQuote.self)
                    .filter("bookId == %@", self.currentState.bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)
                let quotes = realmQuotes.map { $0.toQuote() }

                observer.onNext(.setQuotes(Array(quotes)))
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    private func deleteQuoteFromRealm(_ quoteId: String) -> Observable<Mutation> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                guard let objectId = try? ObjectId(string: quoteId),
                      let quote = realm.object(ofType: RealmQuote.self, forPrimaryKey: objectId) else {
                    observer.onNext(.setError(NSError(domain: "QuoteNotFound", code: 404)))
                    observer.onCompleted()
                    return Disposables.create()
                }

                try realm.write {
                    realm.delete(quote)
                }
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}