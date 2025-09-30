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
        case deleteQuote(RealmQuote)
    }

    enum Mutation {
        case setQuotes([RealmQuote])
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var bookId: String
        var quotes: [RealmQuote] = []
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

        case .deleteQuote(let quote):
            return Observable.concat([
                Observable.just(.setLoading(true)),
                deleteQuoteFromRealm(quote),
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
                let quotes = realm.objects(RealmQuote.self)
                    .filter("bookId == %@", self.currentState.bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)
                let quoteArray = Array(quotes)

                observer.onNext(.setQuotes(quoteArray))
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    private func deleteQuoteFromRealm(_ quote: RealmQuote) -> Observable<Mutation> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
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