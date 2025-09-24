//
//  UILabel+.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

extension UILabel {
    func calculateHeight(constrainedTo width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text?.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font!],
            context: nil
        )
        return ceil(boundingBox?.height ?? 0)
    }
}
