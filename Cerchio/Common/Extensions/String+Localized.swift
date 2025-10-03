//
//  String+.swift
//  SeSAC7Recap2
//
//  Created by 송재훈 on 9/4/25.
//

import Foundation

extension String {
    init(localized: Localized) {
        self = localized.rawValue.localized
    }
    
    init(argumentLocalized: ArgumentLocalized, args: [CVarArg]) {
        self = String(format: argumentLocalized.rawValue.localized, args)
    }
    
    private var localized: String {
        NSLocalizedString(self, comment: self)
    }
}
