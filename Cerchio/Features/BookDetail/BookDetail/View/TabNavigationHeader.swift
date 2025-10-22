//
//  TabNavigationHeader.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

final class TabNavigationHeader: UICollectionReusableView, IsIdentifiable {
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        return stack
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .forestGreen
        return view
    }()

    private let bottomBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private var tabButtons: [UIButton] = []
    private var indicatorLeadingConstraint: Constraint?

    // MARK: - Properties
    var onTabSelected: ((BookDetailViewController.Section) -> Void)?
    private var currentSelectedTab: BookDetailViewController.Section = .readingRecords

    private let tabs: [(title: String, section: BookDetailViewController.Section)] = [
        ("독서 기록", .readingRecords),
        ("인용구", .savedQuotes),
        ("사진", .photoPages),
        ("설정", .settings)
    ]

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .systemBackground

        tabs.forEach { tab in
            let button = createTabButton(title: tab.title, section: tab.section)
            tabButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        addSubview(stackView)
        addSubview(bottomBorderView)
        addSubview(indicatorView)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(48)
        }

        bottomBorderView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(0.5)
            $0.bottom.equalToSuperview()
        }

        indicatorView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom)
            $0.height.equalTo(2)
            $0.width.equalTo(stackView).dividedBy(tabs.count)
            self.indicatorLeadingConstraint = $0.leading.equalTo(stackView).constraint
        }
    }

    private func createTabButton(title: String, section: BookDetailViewController.Section) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .secondaryLabel
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.tag = indexForSection(section)
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        button.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            config?.baseForegroundColor = button.isSelected ? .label : .secondaryLabel

            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = button.isSelected ? .custom(weight: .bold, size: 16) : .custom(weight: .medium, size: 16)
                return outgoing
            }

            button.configuration = config
        }

        return button
    }

    // MARK: - Actions
    @objc private func tabButtonTapped(_ sender: UIButton) {
        HapticFeedbackManager.shared.selection()
        let section = sectionForIndex(sender.tag)
        selectTab(section: section, animated: true)
        onTabSelected?(section)
    }

    // MARK: - Public Methods
    func selectTab(section: BookDetailViewController.Section, animated: Bool) {
        guard currentSelectedTab != section else { return }
        currentSelectedTab = section

        let index = indexForSection(section)
        updateButtonStates(selectedIndex: index)
        moveIndicator(to: index, animated: animated)
    }

    // MARK: - Private Methods
    private func updateButtonStates(selectedIndex: Int) {
        tabButtons.enumerated().forEach { idx, button in
            button.isSelected = idx == selectedIndex
        }
    }

    private func moveIndicator(to index: Int, animated: Bool) {
        let offset = CGFloat(index) * (bounds.width / CGFloat(tabs.count))

        if animated {
            indicatorLeadingConstraint?.update(offset: offset)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.layoutIfNeeded()
            }
        } else {
            indicatorLeadingConstraint?.update(offset: offset)
        }
    }

    private func indexForSection(_ section: BookDetailViewController.Section) -> Int {
        return tabs.firstIndex(where: { $0.section == section }) ?? 0
    }

    private func sectionForIndex(_ index: Int) -> BookDetailViewController.Section {
        guard index >= 0 && index < tabs.count else { return .readingRecords }
        return tabs[index].section
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTabSelected = nil
        currentSelectedTab = .readingRecords
        updateButtonStates(selectedIndex: 0)
        moveIndicator(to: 0, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let index = indexForSection(currentSelectedTab)
        moveIndicator(to: index, animated: false)
    }
}
