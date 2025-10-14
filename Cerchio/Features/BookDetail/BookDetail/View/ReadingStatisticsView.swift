//
//  ReadingStatisticsView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import UIKit
import SnapKit

enum ReadingStatisticsPeriod: Int {
    case total = 0
    case today = 1
    case week = 2
    case month = 3
}

final class ReadingStatisticsView: UIView {

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "BookBackground")?.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(named: "ForestGreen")
        label.textAlignment = .center
        return label
    }()

    private let sessionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(named: "ForestGreen")?.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 독서 기록이 없습니다"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor(named: "ForestGreen")?.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Properties

    private var statistics: ReadingStatistics?
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
        addSubview(containerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(sessionLabel)
        containerView.addSubview(emptyLabel)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.centerX.equalToSuperview()
        }

        sessionLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
        }

        emptyLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    // MARK: - Configuration

    func configure(with statistics: ReadingStatistics, period: ReadingStatisticsPeriod = .total) {
        self.statistics = statistics
        self.currentPeriod = period
        updateUI()
    }

    func updatePeriod(_ period: ReadingStatisticsPeriod) {
        self.currentPeriod = period
        updateUI()
    }

    private func updateUI() {
        guard let statistics = statistics else { return }

        if statistics.isEmpty {
            showEmptyState()
        } else {
            showStatistics(statistics, period: currentPeriod)
        }
    }

    private func showEmptyState() {
        emptyLabel.isHidden = false
        timeLabel.isHidden = true
        sessionLabel.isHidden = true
    }

    private func showStatistics(_ statistics: ReadingStatistics, period: ReadingStatisticsPeriod) {
        emptyLabel.isHidden = true
        timeLabel.isHidden = false
        sessionLabel.isHidden = false

        let time: String
        let sessions: Int

        switch period {
        case .total:
            time = statistics.totalTimeFormatted
            sessions = statistics.totalSessions
        case .today:
            time = statistics.todayTimeFormatted
            sessions = statistics.todaySessions
        case .week:
            time = statistics.weekTimeFormatted
            sessions = statistics.weekSessions
        case .month:
            time = statistics.monthTimeFormatted
            sessions = statistics.monthSessions
        }

        timeLabel.text = time
        sessionLabel.text = "\(sessions)회 독서"
    }
}
