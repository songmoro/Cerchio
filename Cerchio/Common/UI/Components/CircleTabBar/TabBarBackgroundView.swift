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
            .fill(Color(UIColor.systemBackground))
            .mask(backgroundMask)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            .ignoresSafeArea()
    }
    
    private var backgroundMask: some View {
        Rectangle()
            .overlay(
                Group {
                    if showMask {
                        Circle()
                            .frame(width: 60, height: 60)
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
