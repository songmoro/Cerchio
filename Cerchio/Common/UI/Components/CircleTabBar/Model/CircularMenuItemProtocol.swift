//
//  CircularMenuItemProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

protocol CircularMenuItemProtocol {
    var name: String { get }
    var image: UIImage? { get }
    var backgroundColor: UIColor { get }
    var action: (() -> Void)? { get }
}

struct CircularMenuItem: CircularMenuItemProtocol {
    let name: String
    let image: UIImage?
    let backgroundColor: UIColor
    let action: (() -> Void)?

    init(name: String, image: UIImage?, backgroundColor: UIColor = .white, action: (() -> Void)? = nil) {
        self.name = name
        self.image = image
        self.backgroundColor = backgroundColor
        self.action = action
    }
}

protocol CircularMenuDragSelectionDelegate: AnyObject {
    func menuDidAppear()
    func menuDidDisappear()
}