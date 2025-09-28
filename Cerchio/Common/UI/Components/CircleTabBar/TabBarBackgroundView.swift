//
//  TabBarBackgroundView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

struct TabBarBackgroundView: View {
    let showMask: Bool
    let floatingButtonFrame: CGRect
    
    var body: some View {
        Rectangle()
            .fill(.forestGreen)
            .mask(backgroundMask)
            .shadow(
                color: .black.opacity(CircleTabBarConstants.Shadow.opacity),
                radius: CircleTabBarConstants.Shadow.tabBarRadius,
                x: CircleTabBarConstants.Shadow.tabBarOffsetX,
                y: CircleTabBarConstants.Shadow.tabBarOffsetY
            )
            .ignoresSafeArea()
    }
    
    private var backgroundMask: some View {
        Rectangle()
            .overlay(
                Group {
                    if showMask {
                        Circle()
                            .frame(
                                width: CircleTabBarConstants.Dimensions.maskSize,
                                height: CircleTabBarConstants.Dimensions.maskSize
                            )
                            .position(
                                x: floatingButtonFrame.midX,
                                y: floatingButtonFrame.midY
                            )
                            .blendMode(.destinationOut)
                    }
                }
            )
    }
}
