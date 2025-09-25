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
        
        circleTabBarViewModel.onTabSelected = { [weak self] index in
            self?.selectedIndex = index
        }
    }
    
    private func updateTabBarItems() {
        guard let viewControllers = viewControllers else { return }
        
        let tabItems = viewControllers.map { viewController in
            CircleTabBarItemModel(
                title: viewController.tabBarItem.title ?? "",
                systemImageName: viewController.tabBarItem.image?.accessibilityIdentifier ?? "questionmark",
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
    let systemImageName: String
    let tag: Int
}

struct CircleTabBarView: View {
    @ObservedObject var viewModel: CircleTabBarViewModel
    @State private var floatingButtonFrame: CGRect = .zero
    @State private var showMask: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .mask(
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
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                .ignoresSafeArea()
            
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
            
            HStack(spacing: 0) {
                ForEach(Array(viewModel.tabItems.enumerated()), id: \.element.id) { index, item in
                    CircleTabBarButtonView(
                        item: item,
                        isSelected: index == viewModel.selectedIndex,
                        onFrameChange: { frame in
                            if index == viewModel.selectedIndex {
                                floatingButtonFrame = frame
                            }
                        },
                        onFloatingComplete: {
                            if index == viewModel.selectedIndex {
                                showMask = true
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

struct CircleTabBarButtonView: View {
    let item: CircleTabBarItemModel
    let isSelected: Bool
    let onFrameChange: (CGRect) -> Void
    let onFloatingComplete: () -> Void
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.systemImageName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .offset(y: isSelected ? -18 : 0)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    updateFrame(geometry, isFloating: isSelected)
                                }
                                .onChange(of: isSelected) { selected in
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
                        }
                    )
                
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
//            .border(.orange)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
