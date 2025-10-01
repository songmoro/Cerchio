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
    // RealmBook-based methods (legacy)
    func getAllBooks() -> Observable<[RealmBook]>
    func getBook(by id: String) -> Observable<RealmBook?>
    func saveBook(_ book: RealmBook) -> Observable<RealmBook>
    func deleteBook(_ book: RealmBook) -> Observable<Void>
    func deleteBooksWithRelatedData(_ books: [RealmBook]) -> Observable<Void>
    func deleteBooksByIds(_ bookIds: [ObjectId]) -> Observable<Void>

    // Book struct-based methods (preferred)
    func getAllBooksAsStruct() -> Observable<[Book]>
    func getBookByISBN(_ isbn: String) -> Observable<Book?>
    func bookExistsByISBN(_ isbn: String) -> Observable<Bool>
    func saveBookStruct(_ book: Book) -> Observable<Book>
    func deleteBookByISBN(_ isbn: String) -> Observable<Void>
    func deleteBooksByISBNs(_ isbns: [String]) -> Observable<Void>

    // Favorite methods
    func toggleFavorite(bookId: String) -> Observable<Bool>
    func getFavoriteBooks() -> Observable<[Book]>

    // Data management
    func deleteAllData() -> Observable<Void>
}

final class BookRepository: BaseRepository<RealmBook>, BookRepositoryProtocol {

    // MARK: - BookRepositoryProtocol
    func getAllBooks() -> Observable<[RealmBook]> {
        return fetch()
    }

    func getBook(by id: String) -> Observable<RealmBook?> {
        return findById(id)
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
                // Check if book is still valid before deletion
                guard !book.isInvalidated else {
                    continue // Skip already deleted books
                }

                let bookId = String(describing: book.id)

                // 관련된 인용구들 삭제
                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookId)
                self.realm.delete(quotesToDelete)

                // 관련된 사진들 삭제
                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
                self.realm.delete(photosToDelete)

                // 관련된 태그들 삭제
                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookId)
                self.realm.delete(tagsToDelete)

                // 책 삭제
                self.realm.delete(book)
            }
            return ()
        }
    }

    func deleteBooksByIds(_ bookIds: [ObjectId]) -> Observable<Void> {
        return performWriteTransaction {
            for bookId in bookIds {
                // Find book by ID
                guard let book = self.realm.object(ofType: RealmBook.self, forPrimaryKey: bookId),
                      !book.isInvalidated else {
                    continue
                }

                let bookIdString = String(describing: bookId)

                // 관련된 인용구들 삭제
                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
                self.realm.delete(quotesToDelete)

                // 관련된 사진들 삭제
                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
                self.realm.delete(photosToDelete)

                // 관련된 태그들 삭제
                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
                self.realm.delete(tagsToDelete)

                // 책 삭제
                self.realm.delete(book)
            }
            return ()
        }
    }

    // MARK: - Book Struct-based Methods

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
            // Book의 id로 기존 RealmBook 찾기
            if let objectId = try? ObjectId(string: book.id),
               let existingBook = self.realm.object(ofType: RealmBook.self, forPrimaryKey: objectId) {
                // 기존 책 업데이트
                print("📚 Updating existing book - Before: startDate=\(String(describing: existingBook.startDate)), endDate=\(String(describing: existingBook.endDate))")
                print("📚 New values: startDate=\(String(describing: book.startDate)), endDate=\(String(describing: book.endDate))")

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

                print("📚 After update: startDate=\(String(describing: existingBook.startDate)), endDate=\(String(describing: existingBook.endDate))")
                return existingBook.toBook()
            } else {
                // 새 책 생성
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

            // 관련된 인용구들 삭제
            let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
            self.realm.delete(quotesToDelete)

            // 관련된 사진들 삭제
            let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
            self.realm.delete(photosToDelete)

            // 관련된 태그들 삭제
            let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
            self.realm.delete(tagsToDelete)

            // 책 삭제
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

                // 관련된 인용구들 삭제
                let quotesToDelete = self.realm.objects(RealmQuote.self).filter("bookId == %@", bookIdString)
                self.realm.delete(quotesToDelete)

                // 관련된 사진들 삭제
                let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookIdString)
                self.realm.delete(photosToDelete)

                // 관련된 태그들 삭제
                let tagsToDelete = self.realm.objects(RealmTag.self).filter("bookId == %@", bookIdString)
                self.realm.delete(tagsToDelete)

                // 책 삭제
                self.realm.delete(book)
            }
            return ()
        }
    }

    // MARK: - Favorite Methods

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

    // MARK: - Data Management

    func deleteAllData() -> Observable<Void> {
        return performWriteTransaction {
            // 모든 태그 삭제
            let allTags = self.realm.objects(RealmTag.self)
            self.realm.delete(allTags)

            // 모든 인용구 삭제
            let allQuotes = self.realm.objects(RealmQuote.self)
            self.realm.delete(allQuotes)

            // 모든 사진 삭제
            let allPhotos = self.realm.objects(RealmPhoto.self)
            self.realm.delete(allPhotos)

            // 모든 책 삭제
            let allBooks = self.realm.objects(RealmBook.self)
            self.realm.delete(allBooks)

            return ()
        }
    }

    // MARK: - Helper Methods
    private func performWriteTransaction<U>(_ operation: @escaping () throws -> U) -> Observable<U> {
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
}