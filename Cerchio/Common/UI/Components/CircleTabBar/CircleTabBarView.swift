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
    @State private var showMask: Bool = false // 마스크 표시 상태
    
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showMask = true
            }
        }
    }
    
    private func updateFloatingFrame() {
        guard !viewModel.tabItems.isEmpty else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let tabWidth = (screenWidth - 32) / CGFloat(viewModel.tabItems.count)
        let buttonCenterX = 16 + tabWidth * (CGFloat(viewModel.selectedIndex) + 0.5)
        
        floatingButtonFrame = CGRect(
            x: buttonCenterX - 12,
            y: 25,
            width: 24,
            height: 24
        )
    }
}
