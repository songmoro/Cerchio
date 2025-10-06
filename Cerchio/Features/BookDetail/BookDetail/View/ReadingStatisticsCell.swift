//
//  ReadingStatisticsCell.swift
//  Cerchio
//
//  Created by Claude on 10/6/25.
//

import UIKit
import SnapKit

final class ReadingStatisticsCell: UICollectionViewCell, IsIdentifiable {

    // MARK: - UI Components

    private let statisticsView = ReadingStatisticsView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(statisticsView)

        statisticsView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with statistics: ReadingStatistics, period: ReadingStatisticsPeriod) {
        statisticsView.configure(with: statistics, period: period)
    }

    func updatePeriod(_ period: ReadingStatisticsPeriod) {
        statisticsView.updatePeriod(period)
    }
}
