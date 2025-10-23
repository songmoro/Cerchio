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
    private let titleLabel = TransitionAnimatedLabel()
    private let timerPickerView = SVGTimerPickerView(maskImageName: "ClearLogo", svgFileName: "ScaledClearLogo")
    private let startButton = UIButton(type: .system)

    var onStartTimer: ((Int) -> Void)?

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground
        navigationItem.title = "독서 기록"

        setupTitleLabel()
        setupTimerPicker()
        setupStartButton()
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
            self?.titleLabel.text = String(argumentLocalized: .`timer.minutes_format`, args: [minutes])
        }
        titleLabel.text = String(argumentLocalized: .`timer.minutes_format`, args: [timerPickerView.selectedMinutes])
        view.addSubview(timerPickerView)
    }

    private func setupStartButton() {
        var config = UIButton.Configuration.filled()
        config.title = "시작"
        config.baseBackgroundColor = .forestGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        startButton.configuration = config

        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)

        view.addSubview(startButton)
    }

    @objc private func startButtonTapped() {
        onStartTimer?(timerPickerView.selectedMinutes)
    }

    private func setupLayout() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(80)
        }

        timerPickerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(320)
        }

        startButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            $0.width.equalTo(200)
            $0.height.equalTo(50)
        }
    }

    override func bind(reactor: ReadingRecordReactor) {

    }
}
