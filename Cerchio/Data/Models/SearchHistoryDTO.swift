//
//  SearchHistoryDTO.swift
//  Cerchio
//
//  Created by 송재훈 on 10/31/25.
//

import Foundation
import RealmSwift

nonisolated struct SearchHistoryDTO: Hashable, Sendable {
    let id: String
    let keyword: String

    init(from realmObject: RealmSearchHistory) {
        self.id = "\(realmObject.id)"
        self.keyword = realmObject.keyword
    }
}
