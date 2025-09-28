//
//  CircleTabBarButtonView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

import SwiftUI

struct CircleTabBarButtonView: View {
    let item: CircleTabBarItemModel
    let isSelected: Bool
    let onFrameChange: (CGRect) -> Void
    let onFloatingComplete: () -> Void
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: CircleTabBarConstants.Dimensions.iconSpacing) {
                buttonIcon
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var buttonIcon: some View {
        Image(uiImage: item.image.withRenderingMode(.alwaysTemplate))
            .font(.custom(weight: .medium, size: CircleTabBarConstants.Dimensions.iconSize))
            .foregroundColor(.bookBackground)
            .offset(y: isSelected ? -CircleTabBarConstants.Animation.floatingOffset : 0)
            .animation(.easeInOut(duration: CircleTabBarConstants.Animation.duration), value: isSelected)
            .background(frameTracker)
    }

    private var frameTracker: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    updateFrame(geometry, isFloating: isSelected)
                }
                .onChange(of: isSelected) { selected in
                    handleSelectionChange(selected, geometry: geometry)
                }
        }
    }

    private func handleSelectionChange(_ selected: Bool, geometry: GeometryProxy) {
        if selected {
            DispatchQueue.main.asyncAfter(deadline: .now() + CircleTabBarConstants.Animation.delay) {
                updateFrame(geometry, isFloating: true)
                onFloatingComplete()
            }
        } else {
            updateFrame(geometry, isFloating: false)
        }
    }

    private func updateFrame(_ geometry: GeometryProxy, isFloating: Bool) {
        var frame = geometry.frame(in: .named(CircleTabBarConstants.CoordinateSpace.tabBar))

        if isFloating {
            frame.origin.y -= CircleTabBarConstants.Animation.floatingOffset
        }

        onFrameChange(frame)
    }
}
