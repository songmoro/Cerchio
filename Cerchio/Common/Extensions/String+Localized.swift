//
//  String+.swift
//  SeSAC7Recap2
//
//  Created by 송재훈 on 9/4/25.
//

import Foundation

extension String {
    // MARK: - 일반 다국어 텍스트
    enum Localized: String {
        
    }
    
    // MARK: - 매개변수 다국어 텍스트
    enum ArgumentLocalized: String {
        
    }
    
    init(localized: Localized) {
        self = localized.rawValue.localized
    }
    
    init(localized: ArgumentLocalized, args: [CVarArg]) {
        self = String(format: localized.rawValue.localized, args)
    }
    
    private var localized: String {
        NSLocalizedString(self, comment: self)
    }
}
