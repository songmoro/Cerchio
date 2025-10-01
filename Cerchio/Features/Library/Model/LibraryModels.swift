//
//  LibraryModels.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

// MARK: - Library Action
enum LibraryAction {
    case loadBooks
    case refreshBooks
    case searchBooks(String)
    case sortBooks(LibrarySortOption)
    case filterBooks(LibraryFilter)
}

// MARK: - Library Mutation
enum LibraryMutation {
    case setBooks([Book])
    case setLoading(Bool)
    case setError(Error?)
    case setSearchQuery(String)
    case setSortOption(LibrarySortOption)
    case setFilter(LibraryFilter?)
}

// MARK: - Library State
struct LibraryState {
    var books: [Book] = []
    var isLoading: Bool = false
    var error: Error?
    var searchQuery: String = ""
    var sortOption: LibrarySortOption = .dateAdded
    var filter: LibraryFilter?

    var filteredBooks: [Book] {
        var result = books

        // Apply search filter
        if !searchQuery.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchQuery) ||
                book.author.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply category filter
        if let filter = filter {
            result = result.filter { book in
                filter.matches(book: book)
            }
        }

        // Apply sorting
        return result.sorted(by: sortOption.comparator)
    }
}

// MARK: - Library Sort Options
enum LibrarySortOption: String, CaseIterable {
    case title = "제목"
    case author = "작가"
    case dateAdded = "추가일"
    case dateRead = "읽은 날짜"

    var displayName: String {
        return rawValue
    }

    var comparator: (Book, Book) -> Bool {
        switch self {
        case .title:
            return { $0.title < $1.title }
        case .author:
            return { $0.author < $1.author }
        case .dateAdded:
            return { $0.dateAdded ?? Date.distantPast > $1.dateAdded ?? Date.distantPast }
        case .dateRead:
            return { $0.dateRead ?? Date.distantPast > $1.dateRead ?? Date.distantPast }
        }
    }
}

// MARK: - Library Filter
struct LibraryFilter {
    let readingStatus: ReadingStatus?
    let category: BookCategory?
    let rating: ClosedRange<Int>?

    init(
        readingStatus: ReadingStatus? = nil,
        category: BookCategory? = nil,
        rating: ClosedRange<Int>? = nil
    ) {
        self.readingStatus = readingStatus
        self.category = category
        self.rating = rating
    }

    func matches(book: Book) -> Bool {
        if let status = readingStatus {
            if book.readingStatus != status {
                return false
            }
        }

        if let category = category {
            if book.category != category {
                return false
            }
        }

        if let ratingRange = rating {
            if let bookRating = book.rating {
                if !ratingRange.contains(bookRating) {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}

// MARK: - Reading Status
enum ReadingStatus: String, CaseIterable, Codable {
    case toRead = "읽을 예정"
    case reading = "읽는 중"
    case completed = "완료"
    case paused = "일시정지"

    var displayName: String {
        return rawValue
    }
}

// MARK: - Library Statistics
struct LibraryStatistics {
    let totalBooks: Int
    let booksRead: Int
    let booksReading: Int
    let booksToRead: Int
    let averageRating: Double?

    init(books: [Book]) {
        self.totalBooks = books.count
        self.booksRead = books.filter { $0.readingStatus == .completed }.count
        self.booksReading = books.filter { $0.readingStatus == .reading }.count
        self.booksToRead = books.filter { $0.readingStatus == .toRead }.count

        let ratingsSum = books.compactMap { $0.rating }.reduce(0, +)
        let ratingsCount = books.compactMap { $0.rating }.count
        self.averageRating = ratingsCount > 0 ? Double(ratingsSum) / Double(ratingsCount) : nil
    }
}
