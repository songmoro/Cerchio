//
//  FullScreenNestedScrollViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

/// Extended version of NestedScrollViewController that provides full-screen layout
/// with transparent navigation bar and content extending under status bar
/// Use this for immersive experiences where info view should reach the top of the screen
@MainActor
open class FullScreenNestedScrollViewController: NestedScrollViewController {

    // MARK: - Override Properties

    /// Adjust sticky threshold to account for safe area top inset
    /// This ensures the tab becomes sticky when it reaches the navigation bar bottom
    open override var stickyThresholdOffset: CGFloat {
        return view.safeAreaInsets.top
    }

    // MARK: - Private Properties

    private var navigationBarBackgroundView: UIView!

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Allow content to extend under navigation bar
        extendedLayoutIncludesOpaqueBars = true

        // Disable automatic content inset adjustment to allow content to start from top
        mainScrollView.contentInsetAdjustmentBehavior = .never

        // Setup navigation bar background view
        setupNavigationBarBackgroundView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Restore navigation bar appearance every time view appears
        setupTransparentNavigationBar()
        navigationController?.navigationBar.tintColor = .bookBackground
    }

    // MARK: - Setup

    private func setupTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func setupNavigationBarBackgroundView() {
        navigationBarBackgroundView = UIView()
        navigationBarBackgroundView.backgroundColor = .forestGreen
        navigationBarBackgroundView.alpha = 0 // Initially hidden

        view.addSubview(navigationBarBackgroundView)

        navigationBarBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }

    // MARK: - Override: Sticky State Change

    open override func tabStickyStateDidChange(isSticky: Bool) {
        super.tabStickyStateDidChange(isSticky: isSticky)

        UIView.animate(withDuration: 0.3) {
            self.navigationBarBackgroundView.alpha = isSticky ? 1.0 : 0.0
        }
    }
}
