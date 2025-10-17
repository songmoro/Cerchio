//
//  ReadingStatisticsView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import UIKit
import SwiftUI
import SnapKit

enum ReadingStatisticsPeriod: Int {
    case total = 0
    case today = 1
    case week = 2
    case month = 3
}

final class ReadingStatisticsView: UIView {

    // MARK: - UI Components

    private var hostingController: UIHostingController<ReadingChartView>?

    // MARK: - Properties

    private var chartData: ReadingChartData?
    private var currentPeriod: ReadingStatisticsPeriod = .total

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
        backgroundColor = .clear
    }

    // MARK: - Configuration

    func configure(with chartData: ReadingChartData) {
        self.chartData = chartData
        self.currentPeriod = chartData.period
        updateChartView()
    }

    func updatePeriod(_ period: ReadingStatisticsPeriod) {
        self.currentPeriod = period
    }

    private func updateChartView() {
        guard let chartData = chartData else { return }

        if let hostingController = hostingController {
            hostingController.rootView = ReadingChartView(chartData: chartData)
            hostingController.view.layoutIfNeeded()
        } else {
            let chartView = ReadingChartView(chartData: chartData)
            let hosting = UIHostingController(rootView: chartView)
            hosting.view.backgroundColor = .clear
            self.hostingController = hosting

            addSubview(hosting.view)
            hosting.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
}
