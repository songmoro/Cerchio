//
//  SearchHistoryScrollView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/30/25.
//

import UIKit
import SnapKit

final class SearchHistoryScrollView: UIView {
    var onHistorySelected: ((String) -> Void)?
    var onEditTapped: (() -> Void)?

    private let headerView = CommonSectionHeader()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(headerView)
        addSubview(scrollView)

        scrollView.addSubview(stackView)

        headerView.configure(title: String(localized: .`search.history.title`), actionTitle: String(localized: .`action.edit`))
        headerView.onActionTapped = { [weak self] in
            self?.onEditTapped?()
        }

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.horizontalEdges.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(-4)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        // Add height constraint for the entire view
        self.snp.makeConstraints {
            heightConstraint = $0.height.equalTo(0).priority(.high).constraint
        }
    }

    func updateHistory(_ keywords: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !keywords.isEmpty else {
            // Set height to 0 when no history
            heightConstraint?.update(offset: 0)
            return
        }

        // Calculate height: header (40) + scroll view (44) + minimal spacing
        let totalHeight: CGFloat = 84
        heightConstraint?.update(offset: totalHeight)

        for keyword in keywords {
            let button = createCapsuleButton(title: keyword)
            stackView.addArrangedSubview(button)
        }
    }

    private func createCapsuleButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .forestGreen
        config.baseBackgroundColor = .clear
        config.background.strokeColor = .forestGreen
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.cornerStyle = .capsule

        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .custom(weight: .regular, size: 14)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(historyButtonTapped(_:)), for: .touchUpInside)

        // Set content hugging to prevent button from expanding
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }

    @objc private func historyButtonTapped(_ sender: UIButton) {
        guard let title = sender.configuration?.title else { return }
        HapticFeedbackManager.shared.impact()
        onHistorySelected?(title)
    }
}
