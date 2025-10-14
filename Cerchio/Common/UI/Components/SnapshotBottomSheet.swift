//
//  SnapshotBottomSheet.swift
//  Cerchio
//
//  Created by 송재훈 on 10/13/25.
//

import UIKit
import SnapKit

class SnapshotBottomSheet: UIView {
    // MARK: - Properties
    var onDismiss: (() -> Void)?

    private(set) var cellSnapshot: UIView
    private let sheetHeight: CGFloat
    private var initialContainerOffset: CGFloat = 0
    
    // MARK: - UI Components
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0
        return view
    }()
    
    private(set) lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private let snapshotContainer = UIView()
    
    // MARK: - Initialization
    init(sourceView: UIView, sheetHeight: CGFloat) {
        // Create snapshot from source view
        let snapshot = sourceView.snapshotView(afterScreenUpdates: true) ?? UIView()
        snapshot.backgroundColor = .systemBackground
        snapshot.frame.size = sourceView.bounds.size
        snapshot.layer.cornerRadius = 12
        snapshot.layer.borderWidth = 1
        snapshot.layer.borderColor = UIColor.forestGreen.cgColor

        self.cellSnapshot = snapshot
        self.sheetHeight = sheetHeight

        super.init(frame: .zero)

        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(dimmingView)
        addSubview(containerView)
        addSubview(snapshotContainer)
        
        snapshotContainer.addSubview(cellSnapshot)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        dimmingView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
        containerView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(sheetHeight)
        }
        
        snapshotContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(containerView.snp.top).offset(cellSnapshot.bounds.height / 2)
            $0.size.equalTo(cellSnapshot.bounds.size)
        }
        
        cellSnapshot.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap))
        dimmingView.addGestureRecognizer(tapGesture)
        
        let containerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(containerPanGesture)
        
        let snapshotPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        snapshotContainer.addGestureRecognizer(snapshotPanGesture)
    }
    
    // MARK: - Actions
    @objc private func handleDimmingTap() {
        dismiss {
            self.onDismiss?()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .began:
            initialContainerOffset = containerView.transform.ty
            
        case .changed:
            let newOffset = max(0, initialContainerOffset + translation.y)
            containerView.transform = CGAffineTransform(translationX: 0, y: newOffset)
            snapshotContainer.transform = CGAffineTransform(translationX: 0, y: newOffset)
            
            let progress = min(1, newOffset / sheetHeight)
            dimmingView.alpha = 1 - progress
            
        case .ended, .cancelled:
            let shouldDismiss = translation.y > sheetHeight / 3 || velocity.y > 1000
            
            if shouldDismiss {
                dismiss {
                    self.onDismiss?()
                }
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: .curveEaseOut
                ) {
                    self.containerView.transform = .identity
                    self.snapshotContainer.transform = .identity
                    self.dimmingView.alpha = 1
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Presentation
    func show(in window: UIWindow) {
        self.frame = window.bounds
        window.addSubview(self)
        
        // Initial position (off-screen)
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        snapshotContainer.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.dimmingView.alpha = 1
                self.containerView.transform = .identity
                self.snapshotContainer.transform = .identity
            }
        )
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.dimmingView.alpha = 0
                self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
                self.snapshotContainer.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
                
            },
            completion: { _ in
                self.removeFromSuperview()
                completion?()
            }
        )
    }
}
