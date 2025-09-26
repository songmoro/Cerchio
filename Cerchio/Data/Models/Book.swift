//
//  Book.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

nonisolated struct Book: Hashable, Decodable {
    let title: String
    let image: String
    let author: String
    let isbn: String
    
    static let sample: [Book] = [
        Book(
            title: "걸리버 여행기1",
            image: "https://shopping-phinf.pstatic.net/main_5567270/55672705636.20250708082049.jpg",
            author: "조나단 스위프트",
            isbn: "9788931025361"
        ),
        Book(
            title: "스위프트 (초보자를 위한 나만의 iOS 앱 만들기)2",
            image: "https://shopping-phinf.pstatic.net/main_3248281/32482815017.20230110165142.jpg",
            author: "탠메이 박시",
            isbn: "9791162243725"
        ),
        Book(
            title: "테일러 스위프트 (나의 이야기로 우리를 노래하다)3",
            image: "https://shopping-phinf.pstatic.net/main_4841440/48414403618.20240614092216.jpg",
            author: "Swift, Taylor",
            isbn: "9788960908901"
        ),
        Book(
            title: "스위프트 프로그래밍 (모던 스위프트 개발의 핵심! 패러다임과 매크로 그리고 동시성까지)4",
            image: "https://shopping-phinf.pstatic.net/main_5492768/54927689611.20250527094732.jpg",
            author: "야곰",
            isbn: "9791169213905"
        ),
        Book(
            title: "걸리버 여행기5",
            image: "https://shopping-phinf.pstatic.net/main_5567270/55672705636.20250708082049.jpg",
            author: "조나단 스위프트",
            isbn: "9788931025361"
        ),
        Book(
            title: "스위프트 (초보자를 위한 나만의 iOS 앱 만들기)6",
            image: "https://shopping-phinf.pstatic.net/main_3248281/32482815017.20230110165142.jpg",
            author: "탠메이 박시",
            isbn: "9791162243725"
        ),
        Book(
            title: "테일러 스위프트 (나의 이야기로 우리를 노래하다)7",
            image: "https://shopping-phinf.pstatic.net/main_4841440/48414403618.20240614092216.jpg",
            author: "Swift, Taylor",
            isbn: "9788960908901"
        ),
        Book(
            title: "스위프트 프로그래밍 (모던 스위프트 개발의 핵심! 패러다임과 매크로 그리고 동시성까지)8",
            image: "https://shopping-phinf.pstatic.net/main_5492768/54927689611.20250527094732.jpg",
            author: "야곰",
            isbn: "9791169213905"
        ),
        Book(
            title: "걸리버 여행기9",
            image: "https://shopping-phinf.pstatic.net/main_5567270/55672705636.20250708082049.jpg",
            author: "조나단 스위프트",
            isbn: "9788931025361"
        ),
        Book(
            title: "스위프트 (초보자를 위한 나만의 iOS 앱 만들기)10",
            image: "https://shopping-phinf.pstatic.net/main_3248281/32482815017.20230110165142.jpg",
            author: "탠메이 박시",
            isbn: "9791162243725"
        ),
        Book(
            title: "테일러 스위프트 (나의 이야기로 우리를 노래하다)11",
            image: "https://shopping-phinf.pstatic.net/main_4841440/48414403618.20240614092216.jpg",
            author: "Swift, Taylor",
            isbn: "9788960908901"
        ),
        Book(
            title: "스위프트 프로그래밍 (모던 스위프트 개발의 핵심! 패러다임과 매크로 그리고 동시성까지)12",
            image: "https://shopping-phinf.pstatic.net/main_5492768/54927689611.20250527094732.jpg",
            author: "야곰",
            isbn: "9791169213905"
        ),
        Book(
            title: "걸리버 여행기13",
            image: "https://shopping-phinf.pstatic.net/main_5567270/55672705636.20250708082049.jpg",
            author: "조나단 스위프트",
            isbn: "9788931025361"
        ),
        Book(
            title: "스위프트 (초보자를 위한 나만의 iOS 앱 만들기)14",
            image: "https://shopping-phinf.pstatic.net/main_3248281/32482815017.20230110165142.jpg",
            author: "탠메이 박시",
            isbn: "9791162243725"
        ),
        Book(
            title: "테일러 스위프트 (나의 이야기로 우리를 노래하다)15",
            image: "https://shopping-phinf.pstatic.net/main_4841440/48414403618.20240614092216.jpg",
            author: "Swift, Taylor",
            isbn: "9788960908901"
        ),
        Book(
            title: "스위프트 프로그래밍 (모던 스위프트 개발의 핵심! 패러다임과 매크로 그리고 동시성까지)16",
            image: "https://shopping-phinf.pstatic.net/main_5492768/54927689611.20250527094732.jpg",
            author: "야곰",
            isbn: "9791169213905"
        )
    ]
}
