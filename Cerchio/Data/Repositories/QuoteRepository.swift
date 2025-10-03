//
//  QuoteRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol QuoteRepositoryProtocol {
    func getAllQuotes() -> Observable<[RealmQuote]>
    func getQuotes(for bookId: String) -> Observable<[RealmQuote]>
    func saveQuote(_ quote: RealmQuote) -> Observable<RealmQuote>
    func deleteQuote(_ quote: RealmQuote) -> Observable<Void>
    func deleteQuotes(for bookId: String) -> Observable<Void>
}

final class QuoteRepository: BaseRepository<RealmQuote>, QuoteRepositoryProtocol {

    // MARK: - QuoteRepositoryProtocol
    func getAllQuotes() -> Observable<[RealmQuote]> {
        return fetch()
    }

    func getQuotes(for bookId: String) -> Observable<[RealmQuote]> {
        return filterAndSort(
            "bookId == %@",
            sortBy: "createdAt",
            ascending: false,
            bookId
        )
    }

    func saveQuote(_ quote: RealmQuote) -> Observable<RealmQuote> {
        return save(quote)
    }

    func deleteQuote(_ quote: RealmQuote) -> Observable<Void> {
        return delete(quote)
    }

    func deleteQuotes(for bookId: String) -> Observable<Void> {
        return performWriteTransaction {
            let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookId)
            self.realm.delete(quotesToDelete)
            return ()
        }
    }

}