//
//  CircleTabBarItemModel.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import UIKit

struct CircleTabBarItemModel: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
    let tag: Int
    
    init(title: String, image: UIImage?, tag: Int) {
        self.title = title
        self.image = image ?? UIImage(systemName: "questionmark") ?? UIImage()
        self.tag = tag
    }
}
