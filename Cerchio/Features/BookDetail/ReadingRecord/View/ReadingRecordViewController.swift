//
//  ReadingRecordViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class ReadingRecordViewController: BaseViewController<ReadingRecordReactor> {
    // MARK: - UI Components
    private let titleLabel = TransitionAnimatedLabel()
    private let timerPickerView = TimerPickerView()

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground
        navigationItem.title = "독서 기록"

        setupTitleLabel()
        setupTimerPicker()
        setupLayout()
    }

    private func setupTitleLabel() {
        titleLabel.font = .custom(weight: .bold, size: 24)
        titleLabel.textColor = UIColor.forestGreen
        titleLabel.textAlignment = .center
        titleLabel.animationOptions = .curveEaseIn

        view.addSubview(titleLabel)
    }

    private func setupTimerPicker() {
        timerPickerView.onTimeChanged = { [weak self] minutes in
            self?.titleLabel.text = String(minutes)
            print("Selected minutes: \(minutes)")
        }
        titleLabel.text = String(timerPickerView.selectedMinutes)
        view.addSubview(timerPickerView)
    }

    private func setupLayout() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(80)
        }

        timerPickerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(320)
        }
    }

    override func bind(reactor: ReadingRecordReactor) {
        // Action

        // State
    }
}
