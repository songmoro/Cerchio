//
//  Font+CustomFont.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

extension Font {
    static func custom(weight pretendard: Pretendard, size: CGFloat) -> Font {
        return self.custom(pretendard.name, size: size)
    }
}
