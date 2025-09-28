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
            VStack(spacing: 4) {
                buttonIcon
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var buttonIcon: some View {
        Image(uiImage: item.image.withRenderingMode(.alwaysTemplate))
            .font(.custom(weight: .medium, size: 24))
            .foregroundColor(.bookBackground)
            .offset(y: isSelected ? -18 : 0)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                updateFrame(geometry, isFloating: true)
                onFloatingComplete()
            }
        } else {
            updateFrame(geometry, isFloating: false)
        }
    }

    private func updateFrame(_ geometry: GeometryProxy, isFloating: Bool) {
        var frame = geometry.frame(in: .named("TabBarCoordinate"))

        if isFloating {
            frame.origin.y -= 18
        }

        onFrameChange(frame)
    }
}