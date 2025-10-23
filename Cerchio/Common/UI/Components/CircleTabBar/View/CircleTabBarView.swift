//
//  CircleTabBarView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

struct CircleTabBarView: View {
    @ObservedObject var viewModel: CircleTabBarViewModel
    @State private var floatingButtonFrame: CGRect = .zero
    @State private var showMask: Bool = false

    var body: some View {
        ZStack {
            TabBarBackgroundView(
                showMask: showMask,
                floatingButtonFrame: floatingButtonFrame
            )

            FloatingButtonBackgroundView(
                showMask: showMask,
                floatingButtonFrame: floatingButtonFrame
            )

            TabBarButtonsContainerView(
                viewModel: viewModel,
                onFrameChange: { frame in
                    floatingButtonFrame = frame
                },
                onFloatingComplete: {
                    showMask = true
                }
            )
        }
        .compositingGroup()
        .onChange(of: viewModel.selectedIndex) { _ in
            showMask = false
            updateFloatingFrame()
        }
        .onAppear {
            updateFloatingFrame()
            var adjustedFrame = floatingButtonFrame
            adjustedFrame.origin.y -= CircleTabBarConstants.Dimensions.floatingAdjustmentY
            floatingButtonFrame = adjustedFrame
            showMask = true
        }
    }

    private func updateFloatingFrame() {
        guard !viewModel.tabItems.isEmpty else { return }

        let screenWidth = UIScreen.main.bounds.width
        let tabWidth = (screenWidth - CircleTabBarConstants.Dimensions.screenInset) / CGFloat(viewModel.tabItems.count)
        let buttonCenterX = CircleTabBarConstants.Dimensions.horizontalPadding + tabWidth * (CGFloat(viewModel.selectedIndex) + 0.5)

        floatingButtonFrame = CGRect(
            x: buttonCenterX - CircleTabBarConstants.Dimensions.buttonHalfWidth,
            y: CircleTabBarConstants.Dimensions.buttonY,
            width: CircleTabBarConstants.Dimensions.buttonSize,
            height: CircleTabBarConstants.Dimensions.buttonSize
        )
    }
}
