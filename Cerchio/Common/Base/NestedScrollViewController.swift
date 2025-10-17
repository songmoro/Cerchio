//
//  NestedScrollViewController.swift
//  NestedCollectionView
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

/// Base class for implementing nested scroll pattern with sticky tab functionality
/// Subclass this to create screens with:
/// - Top info view that scrolls away
/// - Sticky tab that pins to top when scrolling
/// - CollectionView with dynamic content
@MainActor
open class NestedScrollViewController: UIViewController {

    // MARK: - Public Properties

    /// The main scroll view that contains all content
    public private(set) var mainScrollView: UIScrollView!

    /// The collection view that displays your content
    public private(set) var collectionView: UICollectionView!

    /// Height of the sticky tab view
    public var tabHeight: CGFloat { return 48.5 }

    /// Height of the info view (override to customize)
    open var infoViewHeight: CGFloat {
        return UIScreen.main.bounds.height / 2
    }

    // MARK: - Private Properties

    private var contentStackView: UIStackView!
    private var stickyTabContainer: UIView!
    private var stickyTabView: UIView!
    private var infoView: UIView!

    private var collectionViewHeightConstraint: Constraint?
    private var infoViewHeightConstraint: Constraint?
    private var contentSizeObservation: NSKeyValueObservation?

    /// Whether the tab is currently in sticky mode
    public private(set) var isTabSticky = false

    /// Additional offset to adjust sticky threshold (e.g., for safe area)
    /// Override this in subclasses to customize when sticky behavior triggers
    open var stickyThresholdOffset: CGFloat {
        return 0
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupBaseUI()
        setupCustomContent()
        observeContentSize()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Setup Methods (Override Points)

    /// Override this to provide your custom info view
    /// The default implementation creates a simple placeholder view
    open func createInfoView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.3)

        let label = UILabel()
        label.text = "정보 뷰\n(위로 스크롤하면 사라짐)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .medium)

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        return view
    }

    /// Override this to provide your custom sticky tab view
    /// The default implementation creates a simple green view
    open func createStickyTabView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGreen
        return view
    }

    /// Override this to provide your custom collection view layout
    /// The default implementation creates a simple vertical list layout
    open func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }

    /// Override this to register your custom cells and configure data source
    /// Called after the collection view is set up
    open func setupCustomContent() {
        // Subclasses should override this to:
        // 1. Register cells
        // 2. Configure data source
        // 3. Apply initial snapshot
    }

    /// Override this to respond to sticky tab state changes
    /// Called when the tab transitions between sticky and normal mode
    /// - Parameter isSticky: true if tab is now sticky, false if it returned to normal position
    open func tabStickyStateDidChange(isSticky: Bool) {
        // Subclasses can override this to react to sticky state changes
    }

    // MARK: - Base UI Setup

    private func setupBaseUI() {
        // Create info view
        infoView = createInfoView()

        // Create sticky tab view
        stickyTabView = createStickyTabView()

        // Main scroll view
        mainScrollView = UIScrollView()
        mainScrollView.backgroundColor = .systemBackground
        mainScrollView.showsVerticalScrollIndicator = true
        mainScrollView.delegate = self

        view.addSubview(mainScrollView)
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Content stack view
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0

        mainScrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(mainScrollView)
        }

        // Sticky tab container
        stickyTabContainer = UIView()
        stickyTabContainer.backgroundColor = .clear

        // Add components to stack view
        contentStackView.addArrangedSubview(infoView)
        contentStackView.addArrangedSubview(stickyTabContainer)

        // Info view height
        infoView.snp.makeConstraints { make in
            infoViewHeightConstraint = make.height.equalTo(infoViewHeight).constraint
        }

        // Sticky tab container height
        stickyTabContainer.snp.makeConstraints { make in
            make.height.equalTo(tabHeight)
        }

        // Add sticky tab view to container (initial position)
        stickyTabContainer.addSubview(stickyTabView)
        stickyTabView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(tabHeight)
        }

        // Collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false

        contentStackView.addArrangedSubview(collectionView)

        // CollectionView height
        collectionView.snp.makeConstraints { make in
            collectionViewHeightConstraint = make.height.equalTo(100).constraint
        }
    }

    // MARK: - ContentSize Observation

    private func observeContentSize() {
        contentSizeObservation = collectionView.observe(\.contentSize, options: [.new]) { [weak self] _, change in
            guard let self = self, let newSize = change.newValue, newSize.height > 0 else { return }

            self.collectionViewHeightConstraint?.update(offset: newSize.height)

            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    // MARK: - Sticky Tab Management

    private func updateStickyTab(with offsetY: CGFloat) {
        let stickyThreshold = infoViewHeight - stickyThresholdOffset
        let shouldBeSticky = offsetY >= stickyThreshold

        if shouldBeSticky != isTabSticky {
            isTabSticky = shouldBeSticky

            if shouldBeSticky {
                // Sticky mode: attach to top of main view
                stickyTabView.removeFromSuperview()
                view.addSubview(stickyTabView)

                stickyTabView.snp.remakeConstraints { make in
                    make.top.equalTo(view.safeAreaLayoutGuide)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(tabHeight)
                }
            } else {
                // Normal mode: return to container
                stickyTabView.removeFromSuperview()
                stickyTabContainer.addSubview(stickyTabView)

                stickyTabView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(tabHeight)
                }
            }

            view.layoutIfNeeded()

            // Notify subclasses of sticky state change
            tabStickyStateDidChange(isSticky: shouldBeSticky)
        }
    }

    // MARK: - Public Helper Methods

    /// Scroll to a specific section in the collection view
    /// - Parameter sectionIndex: The index of the section to scroll to
    public func scrollToSection(_ sectionIndex: Int) {
        let headerIndexPath = IndexPath(item: 0, section: sectionIndex)

        guard let headerAttributes = collectionView.layoutAttributesForSupplementaryElement(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: headerIndexPath
        ) else { return }

        let headerY = headerAttributes.frame.origin.y
        // Adjust scroll position to show section header above sticky tab
        let absoluteY = infoViewHeight + headerY - stickyThresholdOffset

        mainScrollView.setContentOffset(CGPoint(x: 0, y: absoluteY), animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension NestedScrollViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else { return }
        updateStickyTab(with: scrollView.contentOffset.y)
    }
}
