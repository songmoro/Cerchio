//
//  ReadingRecordsSectionHeader.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import SnapKit

final class ReadingRecordsSectionHeader: UICollectionReusableView, IsIdentifiable {
    // MARK: - UI Components
    private let titleLabel = UILabel()

    private let viewAllButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "전체 보기"
        config.baseForegroundColor = .systemBlue
        config.contentInsets = .zero

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .custom(weight: .medium, size: 16)
                return outgoing
            }
            button.configuration = config
        }
        return button
    }()

    private let segmentedControl: UISegmentedControl = {
        let items = ["전체", "오늘", "이번 주", "이번 달"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()

    // MARK: - Properties
    var onViewAllTapped: (() -> Void)?
    var onPeriodChanged: ((ReadingStatisticsPeriod) -> Void)?

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
        backgroundColor = .clear

        // 타이틀 레이블
        titleLabel.text = "독서 기록"
        titleLabel.font = .custom(weight: .bold, size: 20)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        // 전체 보기 버튼
        viewAllButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
        addSubview(viewAllButton)

        // 세그먼트 컨트롤
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        addSubview(segmentedControl)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }

        viewAllButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(8)
        }
    }

    // MARK: - Actions
    @objc private func viewAllButtonTapped() {
        onViewAllTapped?()
    }

    @objc private func segmentChanged() {
        let period = ReadingStatisticsPeriod(rawValue: segmentedControl.selectedSegmentIndex) ?? .total
        onPeriodChanged?(period)
    }

    // MARK: - Configuration
    func configure(hasRecords: Bool) {
        segmentedControl.isHidden = !hasRecords

        // 기록이 없을 때는 titleLabel이 bottom 제약을 가지도록 조정
        if !hasRecords {
            titleLabel.snp.remakeConstraints {
                $0.top.bottom.leading.equalToSuperview().inset(16)
            }
        } else {
            titleLabel.snp.remakeConstraints {
                $0.top.leading.equalToSuperview().inset(16)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onViewAllTapped = nil
        onPeriodChanged = nil
    }
}
