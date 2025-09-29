//
//  BookDetailModels.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

// MARK: - BookDetail Action
enum BookDetailAction {
    case loadBookDetail(String) // book ID
    case updateReadingStatus(ReadingStatus)
    case updateProgress(Int) // page number
    case addNote(BookNote)
    case updateRating(Int)
    case toggleFavorite
    case shareBook
}

// MARK: - BookDetail Mutation
enum BookDetailMutation {
    case setBook(Book?)
    case setLoading(Bool)
    case setError(Error?)
    case setReadingStatus(ReadingStatus)
    case setProgress(Int)
    case addNote(BookNote)
    case updateNote(BookNote)
    case removeNote(String) // note ID
    case setRating(Int)
    case setFavorite(Bool)
}

// MARK: - BookDetail State
struct BookDetailState {
    var book: Book?
    var isLoading: Bool = false
    var error: Error?
    var notes: [BookNote] = []
    var readingProgress: ReadingProgress?

    var isBookLoaded: Bool {
        return book != nil
    }

    var canUpdateProgress: Bool {
        guard let book = book else { return false }
        return book.readingStatus == .reading
    }
}

// MARK: - Book Note
struct BookNote: Identifiable, Codable {
    let id: String
    let bookId: String
    let content: String
    let pageNumber: Int?
    let chapterName: String?
    let createdAt: Date
    let updatedAt: Date
    let tags: [String]

    init(
        bookId: String,
        content: String,
        pageNumber: Int? = nil,
        chapterName: String? = nil,
        tags: [String] = []
    ) {
        self.id = UUID().uuidString
        self.bookId = bookId
        self.content = content
        self.pageNumber = pageNumber
        self.chapterName = chapterName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
    }
}

// MARK: - Reading Progress
struct ReadingProgress: Codable {
    let bookId: String
    let currentPage: Int
    let totalPages: Int
    let startDate: Date?
    let lastReadDate: Date
    let estimatedTimeToFinish: TimeInterval?

    var progressPercentage: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(currentPage) / Double(totalPages) * 100.0
    }

    var isCompleted: Bool {
        return currentPage >= totalPages
    }

    init(bookId: String, currentPage: Int, totalPages: Int, startDate: Date? = nil) {
        self.bookId = bookId
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.startDate = startDate
        self.lastReadDate = Date()
        self.estimatedTimeToFinish = nil
    }
}

// MARK: - Book Review
struct BookReview: Identifiable, Codable {
    let id: String
    let bookId: String
    let rating: Int // 1-5
    let title: String?
    let content: String
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        bookId: String,
        rating: Int,
        title: String? = nil,
        content: String,
        isPublic: Bool = false
    ) {
        self.id = UUID().uuidString
        self.bookId = bookId
        self.rating = max(1, min(5, rating))
        self.title = title
        self.content = content
        self.isPublic = isPublic
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Book Highlight
struct BookHighlight: Identifiable, Codable {
    let id: String
    let bookId: String
    let text: String
    let pageNumber: Int
    let chapterName: String?
    let color: HighlightColor
    let note: String?
    let createdAt: Date

    init(
        bookId: String,
        text: String,
        pageNumber: Int,
        chapterName: String? = nil,
        color: HighlightColor = .yellow,
        note: String? = nil
    ) {
        self.id = UUID().uuidString
        self.bookId = bookId
        self.text = text
        self.pageNumber = pageNumber
        self.chapterName = chapterName
        self.color = color
        self.note = note
        self.createdAt = Date()
    }
}

// MARK: - Highlight Color
enum HighlightColor: String, CaseIterable, Codable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case red = "red"
    case purple = "purple"

    var displayName: String {
        switch self {
        case .yellow: return "노란색"
        case .green: return "초록색"
        case .blue: return "파란색"
        case .red: return "빨간색"
        case .purple: return "보라색"
        }
    }
}