//
//  ReadingTimerViewController.swift
//  Cerchio
//
//  Created by Claude on 10/3/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class ReadingTimerViewController: BaseViewController<ReadingTimerReactor> {

    // MARK: - UI Components
    private let elapsedTimeLabel = UILabel()
    private let remainingTimeLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let startButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    // MARK: - Properties
    private let completionRelay = PublishRelay<Void>()

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground
        navigationItem.title = "독서 타이머"
        navigationItem.hidesBackButton = true

        setupTimeLabels()
        setupProgressView()
        setupButtons()
        setupLayout()
    }

    private func setupTimeLabels() {
        elapsedTimeLabel.font = .custom(weight: .bold, size: 48)
        elapsedTimeLabel.textColor = .forestGreen
        elapsedTimeLabel.textAlignment = .center
        elapsedTimeLabel.text = "00:00"

        remainingTimeLabel.font = .custom(weight: .medium, size: 24)
        remainingTimeLabel.textColor = .secondaryLabel
        remainingTimeLabel.textAlignment = .center
        remainingTimeLabel.text = "남은 시간: 00:00"

        view.addSubview(elapsedTimeLabel)
        view.addSubview(remainingTimeLabel)
    }

    private func setupProgressView() {
        progressView.progressTintColor = .forestGreen
        progressView.trackTintColor = .forestGreen.withAlphaComponent(0.2)
        progressView.progress = 0

        view.addSubview(progressView)
    }

    private func setupButtons() {
        var startConfig = UIButton.Configuration.filled()
        startConfig.title = "시작"
        startConfig.baseBackgroundColor = .forestGreen
        startConfig.baseForegroundColor = .white
        startConfig.cornerStyle = .medium
        startButton.configuration = startConfig

        var pauseConfig = UIButton.Configuration.filled()
        pauseConfig.title = "일시정지"
        pauseConfig.baseBackgroundColor = .systemOrange
        pauseConfig.baseForegroundColor = .white
        pauseConfig.cornerStyle = .medium
        pauseButton.configuration = pauseConfig
        pauseButton.isHidden = true

        var stopConfig = UIButton.Configuration.filled()
        stopConfig.title = "종료"
        stopConfig.baseBackgroundColor = .systemRed
        stopConfig.baseForegroundColor = .white
        stopConfig.cornerStyle = .medium
        stopButton.configuration = stopConfig

        view.addSubview(startButton)
        view.addSubview(pauseButton)
        view.addSubview(stopButton)
    }

    private func setupLayout() {
        elapsedTimeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-100)
        }

        remainingTimeLabel.snp.makeConstraints {
            $0.top.equalTo(elapsedTimeLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        progressView.snp.makeConstraints {
            $0.top.equalTo(remainingTimeLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(8)
        }

        startButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
            $0.width.equalTo(200)
            $0.height.equalTo(50)
        }

        pauseButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
            $0.width.equalTo(200)
            $0.height.equalTo(50)
        }

        stopButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(startButton.snp.top).offset(-16)
            $0.width.equalTo(200)
            $0.height.equalTo(50)
        }
    }

    override func bind(reactor: ReadingTimerReactor) {
        // Action
        Observable.just(())
            .map { Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // 알림 권한 거부 시 얼럿 표시
        reactor.state.map { _ in }
            .take(1)
            .flatMap { _ in
                NotificationManager.shared.checkAuthorizationStatus()
            }
            .filter { $0 == .denied }
            .asDriver(onErrorJustReturn: .notDetermined)
            .drive(onNext: { [weak self] _ in
                self?.showNotificationDeniedAlert()
            })
            .disposed(by: disposeBag)

        startButton.rx.tap
            .map { Reactor.Action.startTimer }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        pauseButton.rx.tap
            .withLatestFrom(reactor.state.map { $0.timerState })
            .map { state in
                state == .running ? Reactor.Action.pauseTimer : Reactor.Action.resumeTimer
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        stopButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showStopConfirmation()
            })
            .disposed(by: disposeBag)

        // Background/Foreground handling
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map { _ in Reactor.Action.enterBackground }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .do(onNext: { _ in
                // Foreground로 돌아올 때 배지 제거
                NotificationManager.shared.clearBadge()
            })
            .map { _ in Reactor.Action.enterForeground }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state.map { $0.elapsedTimeString }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "00:00")
            .drive(elapsedTimeLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state.map { "남은 시간: \($0.remainingTimeString)" }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "남은 시간: 00:00")
            .drive(remainingTimeLabel.rx.text)
            .disposed(by: disposeBag)

        reactor.state.map { Float($0.progress) }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
            .drive(progressView.rx.progress)
            .disposed(by: disposeBag)

        reactor.state.map { $0.timerState }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .idle)
            .drive(onNext: { [weak self] state in
                self?.updateButtonStates(for: state)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.timerState }
            .filter { $0 == .completed }
            .take(1)
            .asDriver(onErrorJustReturn: .completed)
            .drive(onNext: { [weak self] _ in
                self?.handleCompletion()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods

    private func updateButtonStates(for state: ReadingTimerReactor.TimerState) {
        switch state {
        case .idle:
            startButton.isHidden = false
            pauseButton.isHidden = true
            stopButton.isEnabled = false

        case .running:
            startButton.isHidden = true
            pauseButton.isHidden = false
            var config = pauseButton.configuration
            config?.title = "일시정지"
            pauseButton.configuration = config
            stopButton.isEnabled = true

        case .paused:
            startButton.isHidden = true
            pauseButton.isHidden = false
            var config = pauseButton.configuration
            config?.title = "재개"
            pauseButton.configuration = config
            stopButton.isEnabled = true

        case .completed:
            startButton.isHidden = true
            pauseButton.isHidden = true
            stopButton.isEnabled = false
        }
    }

    private func showStopConfirmation() {
        // 얼럿 표시 시 타이머 일시정지
        reactor?.action.onNext(.pauseTimer)

        let alert = UIAlertController(
            title: "독서 기록 종료",
            message: "독서 기록을 종료하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            // 취소 시 타이머 재개
            self?.reactor?.action.onNext(.resumeTimer)
        })
        alert.addAction(UIAlertAction(title: "종료", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.stopTimer)
        })

        present(alert, animated: true)
    }

    private func handleCompletion() {
        let alert = UIAlertController(
            title: "완료",
            message: "독서 기록이 저장되었습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.completionRelay.accept(())
        })

        present(alert, animated: true)
    }

    private func showNotificationDeniedAlert() {
        let alert = UIAlertController(
            title: "알림 권한 필요",
            message: "타이머 종료 알림을 받으려면 알림 권한이 필요합니다.\n설정에서 알림을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "나중에", style: .cancel) { [weak self] _ in
            self?.reactor?.action.onNext(.notificationPermissionDenied)
        })

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            self?.reactor?.action.onNext(.notificationPermissionDenied)
        })

        present(alert, animated: true)
    }
}

// MARK: - Coordinator Communication
extension ReadingTimerViewController {
    var completion: Observable<Void> {
        completionRelay.asObservable()
    }
}
