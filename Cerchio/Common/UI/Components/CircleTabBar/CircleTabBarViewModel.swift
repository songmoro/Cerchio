//
//  CircleTabBarViewModel.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import UIKit
import Combine

class CircleTabBarViewModel: ObservableObject {
    @Published var tabItems: [CircleTabBarItemModel] = []
    @Published var selectedIndex: Int = 0
    
    var onTabSelected: ((Int) -> Void)?
    
    func selectTab(at index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        onTabSelected?(index)
    }
}
