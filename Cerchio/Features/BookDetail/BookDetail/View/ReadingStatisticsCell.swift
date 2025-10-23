//
//  ReadingStatisticsCell.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import UIKit
import SnapKit

final class ReadingStatisticsCell: UICollectionViewCell, IsIdentifiable {

    private let statisticsView = ReadingStatisticsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(statisticsView)

        statisticsView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(12)
        }
    }

    func configure(with chartData: ReadingChartData, onPeriodChanged: ((ReadingStatisticsPeriod) -> Void)? = nil, onSwipe: ((ReadingChartView.SwipeDirection) -> Void)? = nil) {
        statisticsView.onPeriodChanged = onPeriodChanged
        statisticsView.onSwipe = onSwipe
        statisticsView.configure(with: chartData)
    }

    func updatePeriod(_ period: ReadingStatisticsPeriod) {
        statisticsView.updatePeriod(period)
    }
}
