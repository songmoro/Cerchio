//
//  CircleTabBarController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/25/25.
//

import UIKit
import SwiftUI
import SnapKit
import Combine

class CircleTabBarController: UITabBarController {
    override var viewControllers: [UIViewController]? {
        didSet {
            updateTabBarItems()
        }
    }
    
    override var selectedIndex: Int {
        didSet {
            circleTabBarViewModel.selectedIndex = selectedIndex
        }
    }
    
    private var swiftUITabBarHostingController: UIHostingController<CircleTabBarView>!
    private var circleTabBarViewModel = CircleTabBarViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        
        tabBar.isHidden = true
        delegate = self
    }
    
    private func setupCustomTabBar() {
        let swiftUITabBar = CircleTabBarView(viewModel: circleTabBarViewModel)
        swiftUITabBarHostingController = UIHostingController(rootView: swiftUITabBar)
        
        addChild(swiftUITabBarHostingController)
        view.addSubview(swiftUITabBarHostingController.view)
        
        swiftUITabBarHostingController.didMove(toParent: self)
        swiftUITabBarHostingController.view.backgroundColor = .clear
        
        swiftUITabBarHostingController.view.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(68)
        }
        
//        let tabBarHeight: CGFloat = 83
//        additionalSafeAreaInsets.bottom = tabBarHeight
        
        circleTabBarViewModel.onTabSelected = { [weak self] index in
            self?.selectedIndex = index
        }
    }
    
    private func updateTabBarItems() {
        guard let viewControllers = viewControllers else { return }
        
        let tabItems = viewControllers.map { viewController in
            CircleTabBarItemModel(
                title: viewController.tabBarItem.title ?? "",
                image: viewController.tabBarItem.image,
                tag: viewController.tabBarItem.tag
            )
        }
        
        circleTabBarViewModel.tabItems = tabItems
        circleTabBarViewModel.selectedIndex = selectedIndex
    }
}

extension CircleTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Did select: \(viewController.title ?? "Unknown")")
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("Should select: \(viewController.title ?? "Unknown")")
        return true
    }
}

class CircleTabBarViewModel: ObservableObject {
    @Published var tabItems: [CircleTabBarItemModel] = []
    @Published var selectedIndex: Int = 0
    
    var onTabSelected: ((Int) -> Void)?
    
    func selectTab(at index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        onTabSelected?(index)
    }
}

struct CircleTabBarItemModel: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
    let tag: Int
    
    init(title: String, image: UIImage?, tag: Int) {
        self.title = title
        self.image = image ?? UIImage(systemName: "questionmark") ?? UIImage()
        self.tag = tag
    }
}

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

struct TabBarBackgroundView: View {
    let showMask: Bool
    let floatingButtonFrame: CGRect
    
    var body: some View {
        Rectangle()
            .fill(Color(UIColor.systemBackground))
            .mask(backgroundMask)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            .ignoresSafeArea()
    }
    
    private var backgroundMask: some View {
        Rectangle()
            .overlay(
                Group {
                    if showMask {
                        Circle()
                            .frame(width: 60, height: 60)
                            .position(
                                x: floatingButtonFrame.midX,
                                y: floatingButtonFrame.midY
                            )
                            .blendMode(.destinationOut)
                    }
                }
            )
    }
}

struct FloatingButtonBackgroundView: View {
    let showMask: Bool
    let floatingButtonFrame: CGRect
    
    var body: some View {
        if showMask {
            Circle()
                .frame(width: 44, height: 44)
                .position(
                    x: floatingButtonFrame.midX,
                    y: floatingButtonFrame.midY
                )
                .foregroundColor(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

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

class ProfileViewController: UIViewController {
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Profile"
        
        setupTitleLabel()
    }
    
    private func setupTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.text = "Profile"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
    }
}

class SavedViewController: UIViewController {
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Saved"
        
        view.addSubview(titleLabel)
        titleLabel.text = "Saved Items"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .systemBlue
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

class AddViewController: UIViewController {
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Add"
        
        view.addSubview(titleLabel)
        titleLabel.text = "Add New Item"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .systemBlue
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

class SearchViewController: UIViewController {
    private let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Search"
        
        view.addSubview(searchBar)
        searchBar.placeholder = "Search..."
        searchBar.backgroundColor = .systemGray6
        searchBar.layer.cornerRadius = 12
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
}
