//
//  CircularMenuItemProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

protocol CircularMenuItemProtocol {
    var image: UIImage? { get }
    var backgroundColor: UIColor { get }
    var action: (() -> Void)? { get }
}

struct CircularMenuItem: CircularMenuItemProtocol {
    let image: UIImage?
    let backgroundColor: UIColor
    let action: (() -> Void)?

    init(image: UIImage?, backgroundColor: UIColor = .white, action: (() -> Void)? = nil) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.action = action
    }
}

protocol CircularMenuDragSelectionDelegate: AnyObject {
    func menuDidAppear()
    func menuDidDisappear()
}