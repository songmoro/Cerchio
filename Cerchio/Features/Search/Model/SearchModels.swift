//
//  SearchModels.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

enum SearchState {
    case initial
    case searching
    case results([Book], [BookSearchItem])
    case noResults
    case error(String)
}

extension SearchState {
    var description: String {
        switch self {
        case .initial: return "initial"
        case .searching: return "searching"
        case .results(let books, _): return "results(\(books.count))"
        case .noResults: return "noResults"
        case .error(let message): return "error(\(message))"
        }
    }

    var books: [Book] {
        switch self {
        case .results(let books, _):
            return books
        default:
            return []
        }
    }

    var originalItems: [BookSearchItem] {
        switch self {
        case .results(_, let items):
            return items
        default:
            return []
        }
    }
}

struct SearchQuery {
    let text: String
    let filters: SearchFilters?

    init(text: String, filters: SearchFilters? = nil) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.filters = filters
    }

    var isEmpty: Bool {
        return text.isEmpty
    }
}

struct SearchFilters {
    let category: BookCategory?
    let author: String?
    let publisher: String?
    let yearRange: ClosedRange<Int>?

    init(
        category: BookCategory? = nil,
        author: String? = nil,
        publisher: String? = nil,
        yearRange: ClosedRange<Int>? = nil
    ) {
        self.category = category
        self.author = author
        self.publisher = publisher
        self.yearRange = yearRange
    }
}

enum BookCategory: String, CaseIterable, Codable {
    case fiction = "소설"
    case nonFiction = "비소설"
    case education = "교육"
    case technology = "기술"
    case art = "예술"
    case science = "과학"

    var displayName: String {
        return rawValue
    }
}

struct SearchResultMetadata {
    let totalCount: Int
    let searchDuration: TimeInterval
    let query: SearchQuery
    let timestamp: Date

    init(totalCount: Int, searchDuration: TimeInterval, query: SearchQuery) {
        self.totalCount = totalCount
        self.searchDuration = searchDuration
        self.query = query
        self.timestamp = Date()
    }
}
