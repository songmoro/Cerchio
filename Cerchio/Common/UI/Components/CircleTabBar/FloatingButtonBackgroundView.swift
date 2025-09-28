//
//  FloatingButtonBackgroundView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

struct FloatingButtonBackgroundView: View {
    let showMask: Bool
    let floatingButtonFrame: CGRect
    
    var body: some View {
        if showMask {
            Circle()
                .frame(
                    width: CircleTabBarConstants.Dimensions.floatingBackgroundSize,
                    height: CircleTabBarConstants.Dimensions.floatingBackgroundSize
                )
                .position(
                    x: floatingButtonFrame.midX,
                    y: floatingButtonFrame.midY
                )
                .foregroundColor(.forestGreen)
                .shadow(
                    color: .black.opacity(CircleTabBarConstants.Shadow.opacity),
                    radius: CircleTabBarConstants.Shadow.radius,
                    x: CircleTabBarConstants.Shadow.offsetX,
                    y: CircleTabBarConstants.Shadow.offsetY
                )
        }
    }
}
