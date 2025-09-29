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
            // 탭바 배경과 마스크
            TabBarBackgroundView(
                showMask: showMask,
                floatingButtonFrame: floatingButtonFrame
            )

            // 플로팅 버튼 원형 배경
            FloatingButtonBackgroundView(
                showMask: showMask,
                floatingButtonFrame: floatingButtonFrame
            )

            // 탭바 버튼들
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
            // 앱 시작 시 선택된 탭의 이미지가 이미 떠올라 있으므로
            // 마스크와 배경도 떠올라 있는 위치로 조정
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
