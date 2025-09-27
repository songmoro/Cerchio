//
//  TabBarButtonsContainerView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

struct TabBarButtonsContainerView: View {
    @ObservedObject var viewModel: CircleTabBarViewModel
    let onFrameChange: (CGRect) -> Void
    let onFloatingComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.tabItems.enumerated()), id: \.element.id) { index, item in
                CircleTabBarButtonView(
                    item: item,
                    isSelected: index == viewModel.selectedIndex,
                    onFrameChange: { frame in
                        if index == viewModel.selectedIndex {
                            onFrameChange(frame)
                        }
                    },
                    onFloatingComplete: {
                        if index == viewModel.selectedIndex {
                            onFloatingComplete()
                        }
                    },
                    action: {
                        viewModel.selectTab(at: index)
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 34)
        .coordinateSpace(name: "TabBarCoordinate")
    }
}
