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
                buttonTitle
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonIcon: some View {
        Image(uiImage: item.image)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(isSelected ? .blue : .gray)
            .offset(y: isSelected ? -18 : 0)
            .background(frameTracker)
    }
    
    private var buttonTitle: some View {
        Text(item.title)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(isSelected ? .blue : .gray)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.29) {
                    onFloatingComplete()
                }
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
