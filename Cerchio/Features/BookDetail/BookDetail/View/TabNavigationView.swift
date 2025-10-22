//
//  TabNavigationView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

/// Generic tab navigation view for NestedScrollViewController
/// Supports any tab configuration with title and associated value
final class TabNavigationView<TabValue: Hashable>: UIView {
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
    var onTabSelected: ((TabValue) -> Void)?
    private var currentSelectedTab: TabValue?
    private var tabs: [(title: String, value: TabValue)] = []

    // MARK: - Initialization
    init(tabs: [(title: String, value: TabValue)]) {
        self.tabs = tabs
        super.init(frame: .zero)
        setupViews()
        setupConstraints()

        if let firstTab = tabs.first {
            currentSelectedTab = firstTab.value
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .systemBackground

        tabs.enumerated().forEach { index, tab in
            let button = createTabButton(title: tab.title, index: index)
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

    private func createTabButton(title: String, index: Int) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .secondaryLabel
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        button.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            config?.baseForegroundColor = button.isSelected ? .label : .secondaryLabel

            config?.background.backgroundColor = .clear

            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = button.isSelected ? .custom(weight: .bold, size: 16) : .custom(weight: .medium, size: 16)
                return outgoing
            }

            button.configuration = config
        }

        if index == 0 {
            button.isSelected = true
        }

        return button
    }

    // MARK: - Actions
    @objc private func tabButtonTapped(_ sender: UIButton) {
        guard sender.tag < tabs.count else { return }
        let tabValue = tabs[sender.tag].value
        selectTab(value: tabValue, animated: true)
        onTabSelected?(tabValue)
    }

    // MARK: - Public Methods
    func selectTab(value: TabValue, animated: Bool) {
        guard currentSelectedTab != value else { return }
        currentSelectedTab = value

        guard let index = tabs.firstIndex(where: { $0.value == value }) else { return }
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

    override func layoutSubviews() {
        super.layoutSubviews()
        if let currentTab = currentSelectedTab,
           let index = tabs.firstIndex(where: { $0.value == currentTab }) {
            moveIndicator(to: index, animated: false)
        }
    }
}
