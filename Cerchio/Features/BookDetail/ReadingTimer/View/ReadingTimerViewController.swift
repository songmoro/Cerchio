//
//  ReadingTimerViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class ReadingTimerViewController: BaseViewController<ReadingTimerReactor> {

    // MARK: - UI Components
    private let debugLabel = UILabel()
    private let elapsedTimeLabel = UILabel()
    private let remainingTimeLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let startButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let actionStackView = UIStackView()
    private let photoButton = UIButton(type: .system)
    private let quoteButton = UIButton(type: .system)

    // MARK: - Properties
    private let completionRelay = PublishRelay<Void>()
    private let backButtonTapRelay = PublishRelay<Void>()
    var onPhotoTapped: (() -> Void)?
    var onQuoteTapped: (() -> Void)?

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground
        navigationItem.title = "독서 타이머"

        // 커스텀 뒤로가기 버튼
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: nil,
            action: nil
        )
        // BaseViewController에서 tintColor를 .bookBackground로 설정하므로 별도 설정 불필요
        navigationItem.leftBarButtonItem = backButton

        backButton.rx.tap
            .bind(to: backButtonTapRelay)
            .disposed(by: disposeBag)

        setupDebugLabel()
        setupTimeLabels()
        setupProgressView()
        setupButtons()
        setupActionButtons()
        setupLayout()
    }

    private func setupDebugLabel() {
        debugLabel.font = .custom(weight: .regular, size: 12)
        debugLabel.textColor = .systemRed
        debugLabel.textAlignment = .center
        debugLabel.numberOfLines = 0
        debugLabel.text = "DEBUG"

        view.addSubview(debugLabel)
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

        view.addSubview(startButton)
        view.addSubview(pauseButton)
    }

    private func setupActionButtons() {
        actionStackView.axis = .horizontal
        actionStackView.spacing = 16
        actionStackView.distribution = .fillEqually

        // 사진 버튼
        var photoConfig = UIButton.Configuration.plain()
        photoConfig.image = UIImage(systemName: "camera.fill")
        photoConfig.imagePlacement = .top
        photoConfig.imagePadding = 8
        photoConfig.title = "사진 찍기"
        photoConfig.baseForegroundColor = .forestGreen
        photoButton.configuration = photoConfig
        photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)

        // 문장 버튼
        var quoteConfig = UIButton.Configuration.plain()
        quoteConfig.image = UIImage(systemName: "quote.bubble.fill")
        quoteConfig.imagePlacement = .top
        quoteConfig.imagePadding = 8
        quoteConfig.title = "문장 저장"
        quoteConfig.baseForegroundColor = .forestGreen
        quoteButton.configuration = quoteConfig
        quoteButton.addTarget(self, action: #selector(quoteButtonTapped), for: .touchUpInside)

        actionStackView.addArrangedSubview(photoButton)
        actionStackView.addArrangedSubview(quoteButton)

        view.addSubview(actionStackView)
    }

    @objc private func photoButtonTapped() {
        onPhotoTapped?()
    }

    @objc private func quoteButtonTapped() {
        onQuoteTapped?()
    }

    private func setupLayout() {
        debugLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

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

        actionStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(startButton.snp.top).offset(-20)
            $0.width.equalTo(280)
            $0.height.equalTo(80)
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
    }

    override func bind(reactor: ReadingTimerReactor) {
        // Action
        Observable.just(())
            .do(onNext: { _ in
                // 타이머 화면 진입 시 항상 배지 제거
                NotificationManager.shared.clearBadge()
            })
            .map { Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        startButton.rx.tap
            .map { Reactor.Action.requestTimerStart }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        pauseButton.rx.tap
            .withLatestFrom(reactor.state.map { $0.timerState })
            .map { state in
                state == .running ? Reactor.Action.pauseTimer : Reactor.Action.resumeTimer
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        backButtonTapRelay
            .subscribe(onNext: { [weak self] in
                self?.handleBackButtonTap()
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
        reactor.state.map { $0.debugText }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "DEBUG")
            .drive(debugLabel.rx.text)
            .disposed(by: disposeBag)

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

        // Validation Error 처리
        reactor.state.map { $0.validationError }
            .compactMap { $0 }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .notificationPermissionDenied)
            .drive(onNext: { [weak self] error in
                self?.handleValidationError(error)
            })
            .disposed(by: disposeBag)

        // 중복 세션 처리
        reactor.state
            .map { $0.duplicateSessionInfo }
            .distinctUntilChanged { lhs, rhs in
                if let lhs = lhs, let rhs = rhs {
                    return lhs.sessionId == rhs.sessionId
                }
                return lhs == nil && rhs == nil
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] sessionInfo in
                self?.showDuplicateSessionAlert(sessionInfo)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods

    private func updateButtonStates(for state: TimerStateManager.TimerState) {
        switch state {
        case .idle:
            startButton.isHidden = false
            pauseButton.isHidden = true

        case .running:
            startButton.isHidden = true
            pauseButton.isHidden = false
            var config = pauseButton.configuration
            config?.title = "일시정지"
            pauseButton.configuration = config

        case .paused:
            startButton.isHidden = true
            pauseButton.isHidden = false
            var config = pauseButton.configuration
            config?.title = "재개"
            pauseButton.configuration = config

        case .completed:
            startButton.isHidden = true
            pauseButton.isHidden = true
        }
    }

    private func handleBackButtonTap() {
        guard let reactor = reactor else {
            navigationController?.popViewController(animated: true)
            return
        }

        // idle 상태(시작 전)면 바로 뒤로가기
        if reactor.currentState.timerState == .idle {
            navigationController?.popViewController(animated: true)
            return
        }

        // completed 상태면 바로 뒤로가기
        if reactor.currentState.timerState == .completed {
            navigationController?.popViewController(animated: true)
            return
        }

        // running 또는 paused 상태면 종료 확인
        showExitConfirmation()
    }

    private func showExitConfirmation() {
        guard let reactor = reactor else { return }

        // 현재 타이머 상태 저장
        let wasRunning = reactor.currentState.timerState == .running
        let elapsedSeconds = reactor.currentState.elapsedSeconds
        let minimumSeconds = 58 // ReadingTimerReactor와 동일한 기준

        // 얼럿 표시 시 타이머 일시정지
        if wasRunning {
            reactor.action.onNext(.pauseTimer)
        }

        // 1분 미만: 기록 없이 종료 확인
        if elapsedSeconds < minimumSeconds {
            let alert = UIAlertController(
                title: "독서 타이머 종료",
                message: "기록 시간이 1분 미만입니다.\n기록 없이 종료하시겠습니까?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
                // 취소 시 타이머 재개 (원래 running이었다면)
                if wasRunning {
                    self?.reactor?.action.onNext(.resumeTimer)
                }
            })

            alert.addAction(UIAlertAction(title: "종료", style: .destructive) { [weak self] _ in
                // 세션 정리하고 뒤로가기
                TimerSessionManager.shared.clearActiveSession()

                // 알림 취소
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_complete"])

                // 라이브 액티비티 종료
                if #available(iOS 16.2, *) {
                    _ = LiveActivityManager.shared.endActivity().subscribe()
                }

                self?.navigationController?.popViewController(animated: true)
            })

            present(alert, animated: true)
        }
        // 1분 이상: 저장하고 종료 확인
        else {
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            let timeString = String(format: "%d분 %d초", minutes, seconds)

            let alert = UIAlertController(
                title: "독서 기록 저장",
                message: "\(timeString) 동안의 독서 기록을 저장하고 종료하시겠습니까?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
                // 취소 시 타이머 재개 (원래 running이었다면)
                if wasRunning {
                    self?.reactor?.action.onNext(.resumeTimer)
                }
            })

            alert.addAction(UIAlertAction(title: "저장하고 종료", style: .default) { [weak self] _ in
                // stopTimer 액션 실행 (저장 후 종료)
                self?.reactor?.action.onNext(.stopTimer)
            })

            present(alert, animated: true)
        }
    }

    private func handleCompletion() {
        guard let reactor = reactor else { return }

        let elapsedMinutes = reactor.currentState.elapsedSeconds / 60
        let elapsedSeconds = reactor.currentState.elapsedSeconds % 60
        let timeString = String(format: "%d분 %d초", elapsedMinutes, elapsedSeconds)

        let message = """
        독서 기록이 저장되었습니다.

        📚 \(reactor.currentState.bookTitle)
        ⏱️ \(timeString) 동안 읽었습니다
        """

        let alert = UIAlertController(
            title: "🎉 독서 완료",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.completionRelay.accept(())
        })

        present(alert, animated: true)
    }

    private func handleValidationError(_ error: ReadingTimerReactor.ValidationError) {
        switch error {
        case .notificationPermissionDenied:
            showNotificationDeniedAlert()
        case .liveActivityNotEnabled:
            showLiveActivityDisabledAlert()
        case .sessionTooShort:
            showSessionTooShortAlert()
        }
    }

    private func showNotificationDeniedAlert() {
        let alert = UIAlertController(
            title: "알림 권한 필요",
            message: "타이머 종료 알림을 받으려면 알림 권한이 필요합니다.\n알림 없이 타이머를 시작하거나 설정에서 알림을 허용해주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "알림 없이 시작", style: .default) { [weak self] _ in
            self?.reactor?.action.onNext(.startTimerConfirmed)
        })

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true)
    }

    private func showLiveActivityDisabledAlert() {
        let alert = UIAlertController(
            title: "Live Activity 사용 불가",
            message: "Live Activity를 사용할 수 없습니다. 타이머는 정상적으로 동작합니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.reactor?.action.onNext(.startTimerConfirmed)
        })

        present(alert, animated: true)
    }

    private func showDuplicateSessionAlert(_ sessionInfo: TimerSessionManager.ActiveSession) {
        // 경과 시간 계산
        let targetSeconds = sessionInfo.targetMinutes * 60
        let remaining: Int

        if let pausedAt = sessionInfo.pausedAt {
            remaining = max(0, Int(sessionInfo.targetEndTime.timeIntervalSince(pausedAt)))
        } else {
            remaining = max(0, Int(sessionInfo.targetEndTime.timeIntervalSince(Date())))
        }

        let elapsedSeconds = targetSeconds - remaining
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)

        let alert = UIAlertController(
            title: "진행 중인 타이머가 있습니다",
            message: "\"\(sessionInfo.bookTitle)\" 독서 타이머가 진행 중입니다.\n경과 시간: \(timeString)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "현재 타이머 계속", style: .default) { [weak self] _ in
            // TODO: 기존 타이머 화면으로 이동
            self?.navigationController?.popViewController(animated: true)
        })

        alert.addAction(UIAlertAction(title: "기존 종료하고 새로 시작", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.terminateExistingSessionAndStart)
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func showSessionTooShortAlert() {
        let alert = UIAlertController(
            title: "기록 시간이 너무 짧습니다",
            message: "최소 1분 이상 읽어야 기록할 수 있습니다.\n계속 읽거나 기록 없이 종료하세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "계속 읽기", style: .default) { [weak self] _ in
            // 타이머 재개
            self?.reactor?.action.onNext(.resumeTimer)
        })

        alert.addAction(UIAlertAction(title: "기록 없이 종료", style: .destructive) { [weak self] _ in
            // 세션 정리하고 종료
            TimerSessionManager.shared.clearActiveSession()

            // 알림 취소
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer_complete"])

            // 라이브 액티비티 종료
            if #available(iOS 16.2, *) {
                _ = LiveActivityManager.shared.endActivity().subscribe()
            }

            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }
}

// MARK: - Coordinator Communication
extension ReadingTimerViewController {
    var completion: Observable<Void> {
        completionRelay.asObservable()
    }

    var backButtonTapped: Observable<Void> {
        backButtonTapRelay.asObservable()
    }
}

// MARK: - Debug
extension ReadingTimerViewController {
    func setDebugText(_ text: String) {
        debugLabel.text = text
    }

    func appendDebugText(_ text: String) {
        let currentText = debugLabel.text ?? ""
        debugLabel.text = currentText + "\n" + text
    }

    func clearDebugText() {
        debugLabel.text = "DEBUG"
    }
}
