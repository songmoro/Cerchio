//
//  BookRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol BookRepositoryProtocol {
    func getAllBooks() -> Observable<[RealmBook]>
    func getBook(by id: String) -> Observable<RealmBook?>
    func saveBook(_ book: RealmBook) -> Observable<RealmBook>
    func deleteBook(_ book: RealmBook) -> Observable<Void>
    func deleteBooksWithRelatedData(_ books: [RealmBook]) -> Observable<Void>
    func deleteBooksByIds(_ bookIds: [ObjectId]) -> Observable<Void>

    func getAllBooksAsStruct() -> Observable<[Book]>
    func getBookByISBN(_ isbn: String) -> Observable<Book?>
    func bookExistsByISBN(_ isbn: String) -> Observable<Bool>
    func saveBookStruct(_ book: Book) -> Observable<Book>
    func deleteBookByISBN(_ isbn: String) -> Observable<Void>
    func deleteBooksByISBNs(_ isbns: [String]) -> Observable<Void>

    func toggleFavorite(bookId: String) -> Observable<Bool>
    func getFavoriteBooks() -> Observable<[Book]>

    func updateBookCustomInfo(bookId: String, customTitle: String, customAuthor: String, customCoverImagePath: String?) -> Observable<Void>
    func resetBookCustomInfo(bookId: String) -> Observable<Void>

    func deleteAllData() -> Observable<Void>
}

final class BookRepository: BaseRepository<RealmBook>, BookRepositoryProtocol {

    func getAllBooks() -> Observable<[RealmBook]> {
        return fetch()
    }

    func getBook(by id: String) -> Observable<RealmBook?> {
        return performOnMainThread {
            guard let objectId = try? ObjectId(string: id) else {
                return nil
            }
            return self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId)
        }
    }

    func saveBook(_ book: RealmBook) -> Observable<RealmBook> {
        return save(book)
    }

    func deleteBook(_ book: RealmBook) -> Observable<Void> {
        return delete(book)
    }

    func deleteBooksWithRelatedData(_ books: [RealmBook]) -> Observable<Void> {
        return performWriteTransaction {
            for book in books {
                guard !book.isInvalidated else {
                    continue
                }

                let bookId = String(describing: book.id)

                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookId)
                self.realm.delete(quotesToDelete)

                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
                self.realm.delete(photosToDelete)

                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookId)
                self.realm.delete(tagsToDelete)

                self.realm.delete(book)
            }
            return ()
        }
    }

    func deleteBooksByIds(_ bookIds: [ObjectId]) -> Observable<Void> {
        return performWriteTransaction {
            for bookId in bookIds {
                guard let book = self.realm.object(ofType: RealmBook.self, forPrimaryKey: bookId),
                      !book.isInvalidated else {
                    continue
                }

                let bookIdString = String(describing: bookId)

                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
                self.realm.delete(quotesToDelete)

                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
                self.realm.delete(photosToDelete)

                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
                self.realm.delete(tagsToDelete)

                self.realm.delete(book)
            }
            return ()
        }
    }

    func getAllBooksAsStruct() -> Observable<[Book]> {
        return getAllBooks()
            .map { realmBooks in
                realmBooks.map { $0.toBook() }
            }
    }

    func getBookByISBN(_ isbn: String) -> Observable<Book?> {
        return Observable.create { observer in
            let books = self.realm.objects(RealmBook.self).filter("isbn == %@", isbn)
            if let realmBook = books.first, !realmBook.isInvalidated {
                observer.onNext(realmBook.toBook())
            } else {
                observer.onNext(nil)
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func bookExistsByISBN(_ isbn: String) -> Observable<Bool> {
        return Observable.create { observer in
            let books = self.realm.objects(RealmBook.self).filter("isbn == %@", isbn)
            observer.onNext(!books.isEmpty)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func saveBookStruct(_ book: Book) -> Observable<Book> {
        return performWriteTransaction {
            if let objectId = try? ObjectId(string: book.id),
               let existingBook = self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId) {

                existingBook.title = book.title
                existingBook.link = book.link
                existingBook.image = book.image
                existingBook.author = book.author
                existingBook.discount = book.discount
                existingBook.publisher = book.publisher
                existingBook.isbn = book.isbn
                existingBook.bookDescription = book.bookDescription
                existingBook.pubdate = book.pubdate
                existingBook.cleanTitle = book.cleanTitle
                existingBook.cleanDescription = book.cleanDescription
                existingBook.formattedPubDate = book.formattedPubDate
                existingBook.formattedPrice = book.formattedPrice
                existingBook.priceAsInt = book.priceAsInt
                existingBook.isFavorite = book.isFavorite
                existingBook.totalPages = book.totalPages ?? 0
                existingBook.startDate = book.startDate
                existingBook.endDate = book.endDate

                return existingBook.toBook()
            } else {
                let realmBook = book.toRealmBook()
                self.realm.add(realmBook)
                return realmBook.toBook()
            }
        }
    }

    func deleteBookByISBN(_ isbn: String) -> Observable<Void> {
        return performWriteTransaction {
            let books = self.realm.objects(RealmBook.self).filter("isbn == %@", isbn)
            guard let book = books.first, !book.isInvalidated else {
                return ()
            }

            let bookIdString = String(describing: book.id)

            let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
            self.realm.delete(quotesToDelete)

            let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
            self.realm.delete(photosToDelete)

            let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
            self.realm.delete(tagsToDelete)

            self.realm.delete(book)
            return ()
        }
    }

    func deleteBooksByISBNs(_ isbns: [String]) -> Observable<Void> {
        return performWriteTransaction {
            for isbn in isbns {
                let books = self.realm.objects(RealmBook.self).filter("isbn == %@", isbn)
                guard let book = books.first, !book.isInvalidated else {
                    continue
                }

                let bookIdString = String(describing: book.id)

                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
                self.realm.delete(quotesToDelete)

                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
                self.realm.delete(photosToDelete)

                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
                self.realm.delete(tagsToDelete)

                self.realm.delete(book)
            }
            return ()
        }
    }

    func toggleFavorite(bookId: String) -> Observable<Bool> {
        return performWriteTransaction {
            guard let objectId = try? ObjectId(string: bookId),
                  let book = self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId),
                  !book.isInvalidated else {
                return false
            }

            book.isFavorite.toggle()
            return book.isFavorite
        }
    }

    func getFavoriteBooks() -> Observable<[Book]> {
        return Observable.create { observer in
            let favoriteBooks = self.realm.objects(RealmBook.self).filter("isFavorite == true")
            let books = favoriteBooks.map { $0.toBook() }
            observer.onNext(Array(books))
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func updateBookCustomInfo(bookId: String, customTitle: String, customAuthor: String, customCoverImagePath: String?) -> Observable<Void> {
        return performWriteTransaction {
            guard let objectId = try? ObjectId(string: bookId),
                  let book = self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId),
                  !book.isInvalidated else {
                throw NSError(domain: "BookRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Book not found"])
            }

            book.customTitle = customTitle.isEmpty ? nil : customTitle
            book.customAuthor = customAuthor.isEmpty ? nil : customAuthor
            book.customCoverImagePath = customCoverImagePath

            return ()
        }
    }

    func resetBookCustomInfo(bookId: String) -> Observable<Void> {
        return performWriteTransaction {
            guard let objectId = try? ObjectId(string: bookId),
                  let book = self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId),
                  !book.isInvalidated else {
                throw NSError(domain: "BookRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Book not found"])
            }

            if let customCoverImagePath = book.customCoverImagePath {
                _ = ImageStorageManager.shared.deleteImage(atPath: customCoverImagePath)
            }

            book.customTitle = nil
            book.customAuthor = nil
            book.customCoverImagePath = nil

            return ()
        }
    }

    func deleteAllData() -> Observable<Void> {
        return performWriteTransaction {
            let allTags = self.realm.objects(RealmTag.self)
            self.realm.delete(allTags)

            let allQuotes = self.realm.objects(RealmQuote.self)
            self.realm.delete(allQuotes)

            let allPhotos = self.realm.objects(RealmPhoto.self)
            self.realm.delete(allPhotos)

            let allBooks = self.realm.objects(RealmBook.self)
            self.realm.delete(allBooks)

            return ()
        }
    }

}
