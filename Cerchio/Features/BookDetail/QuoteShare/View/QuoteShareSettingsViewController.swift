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
    func settingsDidChangeBlur(isEnabled: Bool, intensity: CGFloat)
    func settingsDidChangeBlurColor(isEnabled: Bool, color: UIColor, opacity: CGFloat)
    func settingsDidChangeOpacity(isEnabled: Bool, opacity: CGFloat)
    func settingsDidChangeScale(isEnabled: Bool, scale: CGFloat)
    func settingsDidChangeMetadataVisibility(showBookInfo: Bool, showPageNumber: Bool, showDate: Bool)
}

final class QuoteShareSettingsViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: QuoteShareSettingsDelegate?
    private let disposeBag = DisposeBag()

    private var config: QuoteBackgroundConfig

    private var isMinimized = false
    private var fullHeight: CGFloat = 450
    private var minimizedHeight: CGFloat = 60

    // MARK: - Section & Row Types
    enum Section: Int, CaseIterable {
        case background
        case effects
        case metadata
    }

    enum EffectRow: Int, CaseIterable {
        case blur
        case blurColor
        case opacity
        case scale

        var title: String {
            switch self {
            case .blur: return "흐림 효과"
            case .blurColor: return "색상 틴트"
            case .opacity: return "투명도"
            case .scale: return "이미지 크기"
            }
        }

        var minValue: Float {
            switch self {
            case .blur: return 0.0
            case .blurColor: return 0.0
            case .opacity: return 0.0
            case .scale: return 0.0
            }
        }

        var maxValue: Float {
            switch self {
            case .blur: return 1.0
            case .blurColor: return 1.0
            case .opacity: return 1.0
            case .scale: return 1.6
            }
        }

        func formatValue(_ value: Float) -> String {
            switch self {
            case .blur:
                return String(format: "%.0f%%", value * 100)
            case .blurColor:
                return String(format: "%.0f%%", value * 100)
            case .opacity:
                return String(format: "%.0f%%", value * 100)
            case .scale:
                return String(format: "%.0f%%", value * 100)
            }
        }
    }

    enum MetadataRow: Int, CaseIterable {
        case bookInfo
        case pageNumber
        case date

        var title: String {
            switch self {
            case .bookInfo: return "도서 정보"
            case .pageNumber: return "페이지 번호"
            case .date: return "날짜"
            }
        }
    }

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
        label.text = "배경 설정"
        label.font = .custom(weight: .bold, size: 18)
        label.textColor = .label
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SwitchCell.self, forCellReuseIdentifier: SwitchCell.identifier)
        tableView.register(SliderCell.self, forCellReuseIdentifier: SliderCell.identifier)
        tableView.register(ColorPickerCell.self, forCellReuseIdentifier: ColorPickerCell.identifier)
        return tableView
    }()

    // MARK: - Initialization
    init(config: QuoteBackgroundConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(containerView)
        containerView.addSubview(grabberView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
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

        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.horizontalEdges.bottom.equalToSuperview()
        }
    }

    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGrabberTap))
        grabberView.isUserInteractionEnabled = true
        grabberView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    // MARK: - Actions
    @objc private func handleGrabberTap() {
        toggleMinimized()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            if translation.y > 0 && !isMinimized {
                let newHeight = max(minimizedHeight, fullHeight - translation.y)
                updateHeight(newHeight)
            } else if translation.y < 0 && isMinimized {
                let newHeight = min(fullHeight, minimizedHeight - translation.y)
                updateHeight(newHeight)
            }

        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldMinimize: Bool

            if abs(velocity.y) > 500 {
                shouldMinimize = velocity.y > 0
            } else {
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
            self.tableView.alpha = minimized ? 0 : 1
            self.titleLabel.alpha = minimized ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }

    private func updateHeight(_ height: CGFloat) {
        containerView.snp.updateConstraints {
            $0.height.equalTo(height)
        }

        let progress = (height - minimizedHeight) / (fullHeight - minimizedHeight)
        tableView.alpha = progress
        titleLabel.alpha = progress
    }
}

// MARK: - UITableViewDataSource
extension QuoteShareSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .background:
            return 1
        case .effects:
            if !config.isEnabled { return 0 }
            var count = 0
            for effect in EffectRow.allCases {
                count += 1 // toggle
                if effect == .blurColor {
                    count += 2 // color picker + slider
                } else {
                    count += 1 // slider
                }
            }
            return count
        case .metadata:
            return MetadataRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .background:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.identifier, for: indexPath) as! SwitchCell
            cell.configure(title: "배경 이미지", isOn: config.isEnabled)
            cell.onSwitchChanged = { [weak self] isOn in
                self?.handleBackgroundToggle(isOn)
            }
            return cell

        case .effects:
            return configureEffectCell(for: indexPath, in: tableView)

        case .metadata:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.identifier, for: indexPath) as! SwitchCell
            guard let metadataRow = MetadataRow(rawValue: indexPath.row) else {
                return UITableViewCell()
            }
            let isOn = getMetadataEnabled(metadataRow)
            cell.configure(title: metadataRow.title, isOn: isOn)
            cell.onSwitchChanged = { [weak self] isOn in
                self?.handleMetadataToggle(metadataRow, isOn: isOn)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }

        switch sectionType {
        case .background:
            return nil
        case .effects:
            return config.isEnabled ? "효과" : nil
        case .metadata:
            return "표시 정보"
        }
    }
}

// MARK: - UITableViewDelegate
extension QuoteShareSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 44 }

        switch section {
        case .background:
            return 44
        case .effects:
            var currentRow = 0
            for effect in EffectRow.allCases {
                if currentRow == indexPath.row {
                    return 44
                }
                currentRow += 1

                if effect == .blurColor {
                    if currentRow == indexPath.row {
                        return 44
                    }
                    currentRow += 1
                }

                if currentRow == indexPath.row {
                    return 60
                }
                currentRow += 1
            }
            return 44
        case .metadata:
            return 44
        }
    }
}

// MARK: - Helper Methods
extension QuoteShareSettingsViewController {
    private func configureEffectCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        var currentRow = 0
        for effect in EffectRow.allCases {
            if currentRow == indexPath.row {
                let cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.identifier, for: indexPath) as! SwitchCell
                let isOn = getEffectEnabled(effect)
                cell.configure(title: effect.title, isOn: isOn)
                cell.onSwitchChanged = { [weak self] isOn in
                    self?.handleEffectToggle(effect, isOn: isOn)
                }
                return cell
            }
            currentRow += 1

            if effect == .blurColor {
                if currentRow == indexPath.row {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ColorPickerCell.identifier, for: indexPath) as! ColorPickerCell
                    cell.configure(color: config.blurColor, isEnabled: config.isBlurColorEnabled)
                    cell.onColorChanged = { [weak self] color in
                        self?.handleColorChange(color)
                    }
                    return cell
                }
                currentRow += 1
            }

            if currentRow == indexPath.row {
                let cell = tableView.dequeueReusableCell(withIdentifier: SliderCell.identifier, for: indexPath) as! SliderCell
                let value = getEffectValue(effect)
                let isEnabled = getEffectEnabled(effect)
                cell.configure(
                    minValue: effect.minValue,
                    maxValue: effect.maxValue,
                    value: value,
                    formatValue: effect.formatValue,
                    isEnabled: isEnabled
                )
                cell.onValueChanged = { [weak self] newValue in
                    self?.handleEffectValueChange(effect, value: newValue)
                }
                return cell
            }
            currentRow += 1
        }

        return UITableViewCell()
    }

    private func getEffectEnabled(_ effect: EffectRow) -> Bool {
        switch effect {
        case .blur: return config.isBlurEnabled
        case .blurColor: return config.isBlurColorEnabled
        case .opacity: return config.isOpacityEnabled
        case .scale: return config.isScaleEnabled
        }
    }

    private func getEffectValue(_ effect: EffectRow) -> Float {
        switch effect {
        case .blur: return Float(config.blurIntensity)
        case .blurColor: return Float(config.blurColorOpacity)
        case .opacity: return Float(config.imageOpacity)
        case .scale: return Float(config.imageScale)
        }
    }

    private func handleBackgroundToggle(_ isOn: Bool) {
        config.isEnabled = isOn
        delegate?.settingsDidChangeBackground(isEnabled: isOn)
        tableView.reloadData()
    }

    private func handleEffectToggle(_ effect: EffectRow, isOn: Bool) {
        switch effect {
        case .blur:
            config.isBlurEnabled = isOn
            delegate?.settingsDidChangeBlur(isEnabled: isOn, intensity: config.blurIntensity)
        case .blurColor:
            config.isBlurColorEnabled = isOn
            delegate?.settingsDidChangeBlurColor(isEnabled: isOn, color: config.blurColor, opacity: config.blurColorOpacity)
        case .opacity:
            config.isOpacityEnabled = isOn
            delegate?.settingsDidChangeOpacity(isEnabled: isOn, opacity: config.imageOpacity)
        case .scale:
            config.isScaleEnabled = isOn
            delegate?.settingsDidChangeScale(isEnabled: isOn, scale: config.imageScale)
        }
        tableView.reloadRows(at: [IndexPath(row: effect.rawValue * 2 + 1, section: Section.effects.rawValue)], with: .automatic)
    }

    private func handleEffectValueChange(_ effect: EffectRow, value: Float) {
        switch effect {
        case .blur:
            config.blurIntensity = CGFloat(value)
            delegate?.settingsDidChangeBlur(isEnabled: config.isBlurEnabled, intensity: config.blurIntensity)
        case .blurColor:
            config.blurColorOpacity = CGFloat(value)
            delegate?.settingsDidChangeBlurColor(isEnabled: config.isBlurColorEnabled, color: config.blurColor, opacity: config.blurColorOpacity)
        case .opacity:
            config.imageOpacity = CGFloat(value)
            delegate?.settingsDidChangeOpacity(isEnabled: config.isOpacityEnabled, opacity: config.imageOpacity)
        case .scale:
            config.imageScale = CGFloat(value)
            delegate?.settingsDidChangeScale(isEnabled: config.isScaleEnabled, scale: config.imageScale)
        }
    }

    private func handleColorChange(_ color: UIColor) {
        config.blurColor = color
        delegate?.settingsDidChangeBlurColor(isEnabled: config.isBlurColorEnabled, color: config.blurColor, opacity: config.blurColorOpacity)
    }

    private func getMetadataEnabled(_ metadata: MetadataRow) -> Bool {
        switch metadata {
        case .bookInfo: return config.showBookInfo
        case .pageNumber: return config.showPageNumber
        case .date: return config.showDate
        }
    }

    private func handleMetadataToggle(_ metadata: MetadataRow, isOn: Bool) {
        switch metadata {
        case .bookInfo:
            config.showBookInfo = isOn
        case .pageNumber:
            config.showPageNumber = isOn
        case .date:
            config.showDate = isOn
        }
        delegate?.settingsDidChangeMetadataVisibility(
            showBookInfo: config.showBookInfo,
            showPageNumber: config.showPageNumber,
            showDate: config.showDate
        )
    }
}

// MARK: - SwitchCell
class SwitchCell: UITableViewCell {
    static let identifier = "SwitchCell"

    var onSwitchChanged: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 16)
        return label
    }()

    private let switchControl: UISwitch = {
        let toggle = UISwitch()
        return toggle
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        switchControl.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }

    func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        switchControl.isOn = isOn
    }

    @objc private func switchValueChanged() {
        onSwitchChanged?(switchControl.isOn)
    }
}

// MARK: - SliderCell
class SliderCell: UITableViewCell {
    static let identifier = "SliderCell"

    var onValueChanged: ((Float) -> Void)?
    private var formatValue: ((Float) -> String)?

    private let slider: UISlider = {
        let slider = UISlider()
        slider.tintColor = .forestGreen
        return slider
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        contentView.addSubview(slider)
        contentView.addSubview(valueLabel)

        valueLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(60)
        }

        slider.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(valueLabel.snp.trailing)
            $0.bottom.equalToSuperview().inset(8)
        }

        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }

    func configure(minValue: Float, maxValue: Float, value: Float, formatValue: @escaping (Float) -> String, isEnabled: Bool) {
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = value
        slider.isEnabled = isEnabled
        self.formatValue = formatValue
        updateValueLabel(value)
    }

    @objc private func sliderValueChanged() {
        let value = slider.value
        updateValueLabel(value)

        UIView.animate(withDuration: 0.1) {
            self.valueLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.valueLabel.transform = .identity
            }
        }

        onValueChanged?(value)
    }

    private func updateValueLabel(_ value: Float) {
        valueLabel.text = formatValue?(value) ?? "\(value)"
    }
}

// MARK: - ColorPickerCell
class ColorPickerCell: UITableViewCell {
    static let identifier = "ColorPickerCell"

    var onColorChanged: ((UIColor) -> Void)?

    private var selectedColor: UIColor = .white

    private let colorButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "색상 선택"
        config.cornerStyle = .medium
        config.baseBackgroundColor = .forestGreen
        button.configuration = config
        return button
    }()

    private let colorPreview: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        contentView.addSubview(colorButton)
        contentView.addSubview(colorPreview)

        colorButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(36)
        }

        colorPreview.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        colorButton.addTarget(self, action: #selector(colorButtonTapped), for: .touchUpInside)
    }

    func configure(color: UIColor, isEnabled: Bool) {
        selectedColor = color
        colorPreview.backgroundColor = color
        colorButton.isEnabled = isEnabled
        colorPreview.alpha = isEnabled ? 1.0 : 0.5
    }

    @objc private func colorButtonTapped() {
        guard let viewController = findViewController() else { return }

        if #available(iOS 14.0, *) {
            let colorPicker = UIColorPickerViewController()
            colorPicker.selectedColor = selectedColor
            colorPicker.delegate = self
            viewController.present(colorPicker, animated: true)
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ColorPickerCell: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        colorPreview.backgroundColor = selectedColor
        onColorChanged?(selectedColor)
    }

    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        colorPreview.backgroundColor = selectedColor
        onColorChanged?(selectedColor)
    }
}
