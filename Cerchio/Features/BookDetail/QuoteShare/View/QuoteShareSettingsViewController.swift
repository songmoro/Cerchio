//
//  QuoteShareSettingsViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol QuoteShareSettingsDelegate: AnyObject {
    func settingsDidChangeBackground(isEnabled: Bool)
    func settingsDidChangeBlur(intensity: CGFloat)
}

final class QuoteShareSettingsViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: QuoteShareSettingsDelegate?
    private let disposeBag = DisposeBag()

    private var isMinimized = false
    private var fullHeight: CGFloat = 220
    private var minimizedHeight: CGFloat = 60

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "설정"
        label.font = .custom(weight: .bold, size: 18)
        label.textColor = .label
        return label
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        return stackView
    }()

    // Background toggle row
    private let backgroundToggleContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let backgroundToggleLabel: UILabel = {
        let label = UILabel()
        label.text = "배경 이미지"
        label.font = .custom(weight: .medium, size: 16)
        return label
    }()

    private let backgroundToggle: UISwitch = {
        let toggle = UISwitch()
        return toggle
    }()

    // Blur slider row
    private let blurSliderContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let blurLabel: UILabel = {
        let label = UILabel()
        label.text = "흐림 효과"
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let blurSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        return slider
    }()

    // MARK: - Initialization
    init(isBackgroundEnabled: Bool, blurIntensity: CGFloat) {
        super.init(nibName: nil, bundle: nil)
        backgroundToggle.isOn = isBackgroundEnabled
        blurSlider.value = Float(blurIntensity)
        blurSlider.isEnabled = isBackgroundEnabled
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
        setupBindings()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(containerView)
        containerView.addSubview(grabberView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentStackView)

        // Background toggle row
        backgroundToggleContainer.addSubview(backgroundToggleLabel)
        backgroundToggleContainer.addSubview(backgroundToggle)

        // Blur slider row
        blurSliderContainer.addSubview(blurLabel)
        blurSliderContainer.addSubview(blurSlider)

        contentStackView.addArrangedSubview(backgroundToggleContainer)
        contentStackView.addArrangedSubview(blurSliderContainer)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(fullHeight)
        }

        grabberView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(grabberView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(24)
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        // Background toggle row
        backgroundToggleContainer.snp.makeConstraints {
            $0.height.equalTo(44)
        }

        backgroundToggleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        backgroundToggle.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        // Blur slider row
        blurSliderContainer.snp.makeConstraints {
            $0.height.equalTo(60)
        }

        blurLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        blurSlider.snp.makeConstraints {
            $0.top.equalTo(blurLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGrabberTap))
        grabberView.isUserInteractionEnabled = true
        grabberView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    private func setupBindings() {
        // Background toggle
        backgroundToggle.rx.isOn
            .skip(1)
            .subscribe(onNext: { [weak self] isOn in
                self?.blurSlider.isEnabled = isOn
                self?.delegate?.settingsDidChangeBackground(isEnabled: isOn)
            })
            .disposed(by: disposeBag)

        // Blur slider
        blurSlider.rx.value
            .skip(1)
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                self?.delegate?.settingsDidChangeBlur(intensity: CGFloat(value))
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func handleGrabberTap() {
        toggleMinimized()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            // Allow dragging down to minimize, up to expand
            if translation.y > 0 && !isMinimized {
                // Dragging down when expanded
                let newHeight = max(minimizedHeight, fullHeight - translation.y)
                updateHeight(newHeight)
            } else if translation.y < 0 && isMinimized {
                // Dragging up when minimized
                let newHeight = min(fullHeight, minimizedHeight - translation.y)
                updateHeight(newHeight)
            }

        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldMinimize: Bool

            if abs(velocity.y) > 500 {
                // Fast swipe
                shouldMinimize = velocity.y > 0
            } else {
                // Based on position
                let currentHeight = containerView.frame.height
                let threshold = (fullHeight + minimizedHeight) / 2
                shouldMinimize = currentHeight < threshold
            }

            animateToState(minimized: shouldMinimize)

        default:
            break
        }
    }

    private func toggleMinimized() {
        animateToState(minimized: !isMinimized)
    }

    private func animateToState(minimized: Bool) {
        isMinimized = minimized
        let targetHeight = minimized ? minimizedHeight : fullHeight

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.containerView.snp.updateConstraints {
                $0.height.equalTo(targetHeight)
            }
            self.contentStackView.alpha = minimized ? 0 : 1
            self.titleLabel.alpha = minimized ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }

    private func updateHeight(_ height: CGFloat) {
        containerView.snp.updateConstraints {
            $0.height.equalTo(height)
        }

        let progress = (height - minimizedHeight) / (fullHeight - minimizedHeight)
        contentStackView.alpha = progress
        titleLabel.alpha = progress
    }
}
