//
//  Book.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import Foundation

nonisolated struct Book: Hashable, Codable {
    let id: String
    let title: String
    let image: String
    let author: String
    let isbn: String
    let genre: String?
    let totalPages: Int?
    let isFavorite: Bool

    // Extended properties for feature models
    let dateAdded: Date?
    let dateRead: Date?
    let readingStatus: ReadingStatus?
    let category: BookCategory?
    let rating: Int?

    init(
        id: String = UUID().uuidString,
        title: String,
        image: String,
        author: String,
        isbn: String,
        genre: String? = nil,
        totalPages: Int? = nil,
        isFavorite: Bool = false,
        dateAdded: Date? = nil,
        dateRead: Date? = nil,
        readingStatus: ReadingStatus? = nil,
        category: BookCategory? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.author = author
        self.isbn = isbn
        self.genre = genre
        self.totalPages = totalPages
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.dateRead = dateRead
        self.readingStatus = readingStatus
        self.category = category
        self.rating = rating
    }
    
    static let sample: [Book] = [
        Book(
            title: "센과 치히로의 행방불명",
            image: "https://i.imgur.com/J8Y8j5k.png",
            author: "미야자키 하야오",
            isbn: "9788954675291",
            genre: "아동문학",
            totalPages: 192,
            isFavorite: true
        ),
        Book(
            title: "해리 포터와 마법사의 돌",
            image: "https://i.imgur.com/8y7s3m3.jpg",
            author: "J.K. 롤링",
            isbn: "9788983920102",
            genre: "판타지",
            totalPages: 448,
            isFavorite: false
        ),
        Book(
            title: "어린 왕자",
            image: "https://i.imgur.com/5k2R9Xh.jpg",
            author: "앙투안 드 생텍쥐페리",
            isbn: "9788932917245",
            genre: "소설",
            totalPages: 112,
            isFavorite: true
        ),
        Book(
            title: "1984",
            image: "https://i.imgur.com/3x7J8K9.jpg",
            author: "조지 오웰",
            isbn: "9788937460777",
            genre: "SF",
            totalPages: 448,
            isFavorite: false
        ),
        Book(
            title: "데미안",
            image: "https://i.imgur.com/9K8J3m2.jpg",
            author: "헤르만 헤세",
            isbn: "9788937462788",
            genre: "소설",
            totalPages: 288,
            isFavorite: true
        ),
        Book(
            title: "죄와 벌",
            image: "https://i.imgur.com/7Y4K8m3.jpg",
            author: "표도르 도스토옙스키",
            isbn: "9788937462009",
            genre: "고전문학",
            totalPages: 864,
            isFavorite: false
        ),
        Book(
            title: "호밀밭의 파수꾼",
            image: "https://i.imgur.com/2K8Y3j7.jpg",
            author: "J.D. 샐린저",
            isbn: "9788982814471",
            genre: "소설",
            totalPages: 336,
            isFavorite: true
        ),
        Book(
            title: "위대한 개츠비",
            image: "https://i.imgur.com/5m3K8Y7.jpg",
            author: "F. 스콧 피츠제럴드",
            isbn: "9788937460784",
            genre: "고전문학",
            totalPages: 256,
            isFavorite: false
        ),
        Book(
            title: "노인과 바다",
            image: "https://i.imgur.com/8K3Y7m2.jpg",
            author: "어니스트 헤밍웨이",
            isbn: "9788937460456",
            genre: "고전문학",
            totalPages: 144,
            isFavorite: true
        ),
        Book(
            title: "반지의 제왕",
            image: "https://i.imgur.com/3Y8K2m7.jpg",
            author: "J.R.R. 톨킨",
            isbn: "9788983920591",
            genre: "판타지",
            totalPages: 1216,
            isFavorite: false
        )
    ]
}
