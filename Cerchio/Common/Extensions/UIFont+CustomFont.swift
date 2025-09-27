//
//  UIFont+CustomFont.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import UIKit

extension UIFont {
    static func custom(weight pretendard: Pretendard, size: CGFloat) -> UIFont {
        return self.init(name: pretendard.name, size: size) ?? Self.systemFont(ofSize: size)
    }
}
