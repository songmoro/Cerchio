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
                .frame(width: 40, height: 40)
                .position(
                    x: floatingButtonFrame.midX,
                    y: floatingButtonFrame.midY
                )
                .foregroundColor(.forestGreen)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
