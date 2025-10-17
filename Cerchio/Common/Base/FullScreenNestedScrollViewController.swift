//
//  FullScreenNestedScrollViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit

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

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Allow content to extend under navigation bar
        extendedLayoutIncludesOpaqueBars = true

        // Set navigation bar tint color
        navigationController?.navigationBar.tintColor = .bookBackground

        // Disable automatic content inset adjustment to allow content to start from top
        mainScrollView.contentInsetAdjustmentBehavior = .never

        // Setup initial transparent navigation bar
        updateNavigationBarAppearance(isTabSticky: false)
    }

    // MARK: - Navigation Bar Appearance

    /// Updates the navigation bar appearance based on sticky tab state
    /// - Parameter isTabSticky: Whether the tab is currently sticky
    private func updateNavigationBarAppearance(isTabSticky: Bool) {
        let appearance = UINavigationBarAppearance()

        if isTabSticky {
            // Sticky mode: forestGreen background
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .forestGreen
            appearance.shadowColor = nil
            appearance.shadowImage = UIImage()
        } else {
            // Normal mode: transparent background
            appearance.configureWithTransparentBackground()
            appearance.shadowColor = nil
            appearance.shadowImage = UIImage()
        }

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    // MARK: - Override: Sticky State Change

    open override func tabStickyStateDidChange(isSticky: Bool) {
        super.tabStickyStateDidChange(isSticky: isSticky)
        updateNavigationBarAppearance(isTabSticky: isSticky)
    }
}
