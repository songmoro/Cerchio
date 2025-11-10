//
//  NestedScrollViewController.swift
//  NestedCollectionView
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

class NestedScrollViewController: UIViewController {
    private(set) var mainScrollView: UIScrollView!
    private(set) var collectionView: UICollectionView!
    private(set) var isTabSticky = false
    
    var tabHeight: CGFloat { return 48.5 }
    var infoViewHeight: CGFloat { return UIScreen.main.bounds.height / 2 }
    var stickyThresholdOffset: CGFloat { return 0 }
    
    private var contentStackView: UIStackView!
    private var stickyTabContainer: UIView!
    private var stickyTabView: UIView!
    private var infoView: UIView!
    private var collectionViewHeightConstraint: Constraint?
    private var contentSizeObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupBaseUI()
        setupCustomContent()
        observeContentSize()
    }
    
    func createInfoView() -> UIView {
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
    
    func createStickyTabView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGreen
        return view
    }
    
    func createCollectionViewLayout() -> UICollectionViewLayout {
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
    
    func setupCustomContent() { }
    func tabStickyStateDidChange(isSticky: Bool) { }
    
    private func setupBaseUI() {
        infoView = createInfoView()
        
        stickyTabView = createStickyTabView()
        
        mainScrollView = UIScrollView()
        mainScrollView.backgroundColor = .systemBackground
        mainScrollView.showsVerticalScrollIndicator = true
        mainScrollView.delegate = self
        
        view.addSubview(mainScrollView)
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        
        mainScrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(mainScrollView)
        }
        
        stickyTabContainer = UIView()
        stickyTabContainer.backgroundColor = .clear
        
        contentStackView.addArrangedSubview(infoView)
        contentStackView.addArrangedSubview(stickyTabContainer)

        infoView.snp.makeConstraints { make in
            make.height.equalTo(infoViewHeight)
        }
        
        stickyTabContainer.snp.makeConstraints { make in
            make.height.equalTo(tabHeight)
        }
        
        stickyTabContainer.addSubview(stickyTabView)
        stickyTabView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(tabHeight)
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        
        contentStackView.addArrangedSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            collectionViewHeightConstraint = make.height.equalTo(100).constraint
        }
    }
    
    private func observeContentSize() {
        contentSizeObservation = collectionView.observe(\.contentSize, options: [.new]) { [weak self] _, change in
            guard let self = self, let newSize = change.newValue, newSize.height > 0 else { return }
            
            self.collectionViewHeightConstraint?.update(offset: newSize.height)
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateStickyTab(with offsetY: CGFloat) {
        let stickyThreshold = infoViewHeight - stickyThresholdOffset
        let shouldBeSticky = offsetY >= stickyThreshold
        
        if shouldBeSticky != isTabSticky {
            isTabSticky = shouldBeSticky
            
            if shouldBeSticky {
                stickyTabView.removeFromSuperview()
                view.addSubview(stickyTabView)
                
                stickyTabView.snp.remakeConstraints { make in
                    make.top.equalTo(view.safeAreaLayoutGuide)
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(tabHeight)
                }
            } else {
                stickyTabView.removeFromSuperview()
                stickyTabContainer.addSubview(stickyTabView)
                
                stickyTabView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(tabHeight)
                }
            }
            
            view.layoutIfNeeded()
            
            tabStickyStateDidChange(isSticky: shouldBeSticky)
        }
    }
    
    func scrollToSection(_ sectionIndex: Int) {
        let headerIndexPath = IndexPath(item: 0, section: sectionIndex)
        
        guard let headerAttributes = collectionView.layoutAttributesForSupplementaryElement(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: headerIndexPath
        ) else { return }
        
        let headerY = headerAttributes.frame.origin.y
        let absoluteY = infoViewHeight + headerY - stickyThresholdOffset
        
        mainScrollView.setContentOffset(CGPoint(x: 0, y: absoluteY), animated: true)
    }
}

extension NestedScrollViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else { return }
        updateStickyTab(with: scrollView.contentOffset.y)
    }
}
