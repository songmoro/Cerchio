//
//  AnimatedTextView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import SwiftUI

/// SwiftUI의 contentTransition을 사용한 텍스트 애니메이션
@available(iOS 16.0, *)
struct AnimatedTextView: View {
    let text: String
    let font: Font
    let color: Color

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
    }
}

/// SwiftUI 커스텀 슬라이드 애니메이션
struct CustomSlideTextView: View {
    let text: String
    let font: Font
    let color: Color

    @State private var offset: CGFloat = 0

    var body: some View {
        if #available(iOS 17.0, *) {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .offset(y: offset)
                .onChange(of: text) { oldValue, newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
                .onAppear {
                    offset = -30
                }
        } else {
            Text(text)
        }
    }
}

/// UIViewRepresentable로 UIKit 애니메이션 레이블을 SwiftUI에서 사용
struct TransitionAnimatedLabelView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor

    func makeUIView(context: Context) -> TransitionAnimatedLabel {
        let label = TransitionAnimatedLabel()
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.animationOptions = .transitionFlipFromTop
        return label
    }

    func updateUIView(_ label: TransitionAnimatedLabel, context: Context) {
        label.setText(text, animated: true)
    }
}

/// CATransition 애니메이션 레이블 SwiftUI Wrapper
struct CATransitionAnimatedLabelView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor

    func makeUIView(context: Context) -> CATransitionAnimatedLabel {
        let label = CATransitionAnimatedLabel()
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.transitionType = .push
        label.transitionSubtype = .fromTop
        return label
    }

    func updateUIView(_ label: CATransitionAnimatedLabel, context: Context) {
        label.setText(text, animated: true)
    }
}

/// Custom Slide 애니메이션 레이블 SwiftUI Wrapper
struct CustomSlideAnimatedLabelView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor

    func makeUIView(context: Context) -> CustomSlideAnimatedLabel {
        let view = CustomSlideAnimatedLabel()
        view.font = font
        view.textColor = color
        view.textAlignment = .center
        return view
    }

    func updateUIView(_ view: CustomSlideAnimatedLabel, context: Context) {
        view.setText(text, animated: true)
    }
}

// MARK: - UIKit Hosting Wrapper for ViewController

import SnapKit
import RxSwift
import RxCocoa

/// UIKit에서 SwiftUI AnimatedTextView를 사용하기 위한 Wrapper
@available(iOS 16.0, *)
final class AnimatedTextHostingView: UIView {
    private let hostingController: UIHostingController<AnimatedTextView>

    var text: String {
        didSet {
            updateText()
        }
    }

    var font: Font
    var color: Color

    var rx_text: Binder<String> {
        return Binder(self) { view, text in
            view.text = text
        }
    }

    init(text: String = "", font: Font = .system(size: 64, weight: .bold), color: Color = .red) {
        self.text = text
        self.font = font
        self.color = color

        let swiftUIView = AnimatedTextView(text: text, font: font, color: color)
        self.hostingController = UIHostingController(rootView: swiftUIView)

        super.init(frame: .zero)

        setupHosting()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHosting() {
        hostingController.view.backgroundColor = .clear
        addSubview(hostingController.view)

        // SnapKit 사용
        hostingController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func updateText() {
        hostingController.rootView = AnimatedTextView(text: text, font: font, color: color)
    }

    /// Parent ViewController에 attach
    func attach(to parentViewController: UIViewController) {
        parentViewController.addChild(hostingController)
        hostingController.didMove(toParent: parentViewController)
    }
}

/// UIKit에서 SwiftUI CustomSlideTextView를 사용하기 위한 Wrapper
final class CustomSlideTextHostingView: UIView {
    private let hostingController: UIHostingController<CustomSlideTextView>

    var text: String {
        didSet {
            updateText()
        }
    }

    var font: Font
    var color: Color

    var rx_text: Binder<String> {
        return Binder(self) { view, text in
            view.text = text
        }
    }

    init(text: String = "", font: Font = .system(size: 64, weight: .bold), color: Color = .red) {
        self.text = text
        self.font = font
        self.color = color

        let swiftUIView = CustomSlideTextView(text: text, font: font, color: color)
        self.hostingController = UIHostingController(rootView: swiftUIView)

        super.init(frame: .zero)

        setupHosting()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHosting() {
        hostingController.view.backgroundColor = .clear
        addSubview(hostingController.view)

        // SnapKit 사용
        hostingController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func updateText() {
        hostingController.rootView = CustomSlideTextView(text: text, font: font, color: color)
    }

    /// Parent ViewController에 attach
    func attach(to parentViewController: UIViewController) {
        parentViewController.addChild(hostingController)
        hostingController.didMove(toParent: parentViewController)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        if #available(iOS 16.0, *) {
            AnimatedTextView(
                text: "25",
                font: .system(size: 64, weight: .bold),
                color: .red
            )
        }

        CustomSlideTextView(
            text: "25",
            font: .system(size: 64, weight: .bold),
            color: .red
        )

        TransitionAnimatedLabelView(
            text: "25",
            font: .systemFont(ofSize: 64, weight: .bold),
            color: .systemRed
        )
        .frame(height: 80)

        CATransitionAnimatedLabelView(
            text: "25",
            font: .systemFont(ofSize: 64, weight: .bold),
            color: .systemRed
        )
        .frame(height: 80)

        CustomSlideAnimatedLabelView(
            text: "25",
            font: .systemFont(ofSize: 64, weight: .bold),
            color: .systemRed
        )
        .frame(height: 80)
    }
    .padding()
}
