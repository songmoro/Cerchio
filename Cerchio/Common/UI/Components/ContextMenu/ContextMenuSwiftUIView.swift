//
//  ContextMenuSwiftUIView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import SwiftUI

// MARK: - Main SwiftUI View

struct ContextMenuSwiftUIView: View {
    @ObservedObject var viewModel: ContextMenuViewModel

    var body: some View {
        ZStack {
            // 타겟 뷰 오버레이 (있는 경우)
            if let targetView = viewModel.targetView {
                TargetViewOverlay(
                    targetView: targetView,
                    position: viewModel.position
                )
                .opacity(viewModel.isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isVisible)
            }

            // 원형 메뉴 버튼들
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                ContextMenuButton(
                    item: item,
                    position: viewModel.buttonPosition(for: index),
                    isSelected: viewModel.isButtonSelected(index),
                    isVisible: viewModel.isVisible
                )
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * 0.05),
                    value: viewModel.isVisible
                )
            }
        }
    }
}

// MARK: - TargetView Overlay

struct TargetViewOverlay: UIViewRepresentable {
    let targetView: UIView
    let position: CGPoint

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // 타겟 뷰의 스냅샷 생성
        if let snapshot = createSnapshot(of: targetView) {
            let imageView = UIImageView(image: snapshot)

            // 정확한 좌표 계산을 위해 window 기준으로 변환
            guard let window = targetView.window,
                  let superview = targetView.superview else { return containerView }

            // 타겟 뷰의 프레임을 window 좌표계로 변환
            let targetFrameInWindow = superview.convert(targetView.frame, to: window)

            // 컨테이너 뷰를 window 좌표계로 변환
            let containerFrameInWindow = containerView.convert(containerView.bounds, to: window)

            // 상대적 위치 계산
            imageView.frame = CGRect(
                x: targetFrameInWindow.origin.x - containerFrameInWindow.origin.x,
                y: targetFrameInWindow.origin.y - containerFrameInWindow.origin.y,
                width: targetView.bounds.width,
                height: targetView.bounds.height
            )

            imageView.layer.cornerRadius = targetView.layer.cornerRadius
            imageView.clipsToBounds = true
            imageView.layer.shadowColor = UIColor.black.cgColor
            imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
            imageView.layer.shadowRadius = 8
            imageView.layer.shadowOpacity = 0.3

            containerView.addSubview(imageView)
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func createSnapshot(of view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}

// MARK: - Circular Menu Button

struct ContextMenuButton: View {
    let item: ContextMenuItem
    let position: CGPoint
    let isSelected: Bool
    let isVisible: Bool

    private let buttonSize: CGFloat = 50

    var body: some View {
        Button(action: {
            // 액션은 터치 핸들링에서 처리
        }) {
            ZStack {
                Circle()
                    .fill(Color(item.backgroundColor))
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                if let image = item.image {
                    Image(uiImage: image)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(true) // 터치는 제스처로 처리
        .scaleEffect(isVisible ? (isSelected ? 1.2 : 1.0) : 0)
        .position(isVisible ? position : CGPoint(x: position.x, y: position.y))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Preview

struct ContextMenuSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        let items = [
            ContextMenuItem.create(systemName: "heart", backgroundColor: .systemRed),
            ContextMenuItem.create(systemName: "star", backgroundColor: .systemYellow),
            ContextMenuItem.create(systemName: "bookmark", backgroundColor: .systemBlue),
            ContextMenuItem.create(systemName: "trash", backgroundColor: .systemRed)
        ]

        let viewModel = ContextMenuViewModel(
            position: CGPoint(x: 200, y: 300),
            targetView: nil,
            items: items
        )

        ContextMenuSwiftUIView(viewModel: viewModel)
            .onAppear {
                viewModel.showMenu()
            }
    }
}
