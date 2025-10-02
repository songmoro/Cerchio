//
//  ViewHighlightManager.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit

/// Manages view highlighting with configurable visual effects
class ViewHighlightManager {
    // MARK: - Properties

    private weak var containerView: UIView?
    private weak var originalView: UIView?
    private var highlightedSnapshotView: UIView?
    private let configuration: ViewHighlightConfiguration

    // MARK: - Initialization

    init(configuration: ViewHighlightConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Highlight a view with the configured effects
    /// - Parameters:
    ///   - view: The view to highlight
    ///   - containerView: The container view where the snapshot will be displayed
    ///   - touchPoint: Optional touch point for contextual rotation calculation
    func highlight(view: UIView, in containerView: UIView, touchPoint: CGPoint? = nil) {
        self.containerView = containerView
        self.originalView = view

        // Create snapshot
        guard let snapshot = view.snapshotView(afterScreenUpdates: true) else { return }
        highlightedSnapshotView = snapshot
        
        // Hide original view if configured
        if configuration.hideOriginalView {
            view.alpha = 0
        }

        // Calculate frame in container view coordinates
        guard let superview = view.superview else { return }
        let frameInContainer = superview.convert(view.frame, to: containerView)

        // Apply scale to frame
        let scaledFrame = calculateScaledFrame(originalFrame: frameInContainer)
        snapshot.frame = scaledFrame

        // Apply corner radius
        let cornerRadius: CGFloat
        if let configuredRadius = configuration.cornerRadius {
            // Use configured corner radius
            cornerRadius = configuredRadius * configuration.cornerRadiusMultiplier
        } else if view.layer.cornerRadius > 0 {
            // Use original view's corner radius
            cornerRadius = view.layer.cornerRadius * configuration.cornerRadiusMultiplier
        } else {
            cornerRadius = 0
        }

        if cornerRadius > 0 {
            snapshot.layer.cornerRadius = cornerRadius
            snapshot.layer.masksToBounds = true
        }

        // Apply shadow
        applyShadow(to: snapshot)

        // Calculate and apply transform
        let screenCenter = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
        let viewCenter = CGPoint(x: frameInContainer.midX, y: frameInContainer.midY)
        let transform = calculateTransform(viewCenter: viewCenter, screenCenter: screenCenter)
        snapshot.transform = transform

        // Add to container
        containerView.addSubview(snapshot)

        // Animate in if needed
        animateHighlight()
    }

    /// Remove the highlight and restore the original view
    /// - Parameter completion: Called when dismissal animation completes
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let snapshot = highlightedSnapshotView else {
            completion?()
            return
        }

        if animated {
            UIView.animate(
                withDuration: configuration.animationDuration,
                animations: {
                    snapshot.alpha = 0
                },
                completion: { [weak self] _ in
                    self?.cleanup()
                    completion?()
                }
            )
        } else {
            cleanup()
            completion?()
        }
    }

    // MARK: - Private Methods

    private func calculateScaledFrame(originalFrame: CGRect) -> CGRect {
        // Extract scale from effect
        var scaleMultiplier: CGFloat = 1.0

        switch configuration.effect {
        case .scale(let multiplier):
            scaleMultiplier = multiplier
        case .combined(let effects):
            for effect in effects {
                if case .scale(let multiplier) = effect {
                    scaleMultiplier = multiplier
                    break
                }
            }
        default:
            break
        }

        let scaledWidth = originalFrame.width * scaleMultiplier
        let scaledHeight = originalFrame.height * scaleMultiplier

        return CGRect(
            x: originalFrame.midX - scaledWidth / 2,
            y: originalFrame.midY - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )
    }

    private func calculateTransform(viewCenter: CGPoint, screenCenter: CGPoint) -> CGAffineTransform {
        var transform = configuration.effect.asTransform(
            viewCenter: viewCenter,
            screenCenter: screenCenter
        )

        // Apply contextual rotation if effect contains rotation with 0 degrees
        if case .combined(let effects) = configuration.effect {
            for (index, effect) in effects.enumerated() {
                if case .rotation(let degrees) = effect, degrees == 0 {
                    // Calculate contextual rotation
                    let tiltAngle = calculateContextualTiltAngle(
                        viewCenter: viewCenter,
                        screenCenter: screenCenter
                    )

                    // Rebuild transform with contextual rotation
                    var newEffects = effects
                    newEffects[index] = .rotation(degrees: tiltAngle)

                    transform = ViewHighlightEffect.combined(newEffects).asTransform(
                        viewCenter: viewCenter,
                        screenCenter: screenCenter
                    )
                    break
                }
            }
        }

        return transform
    }

    private func calculateContextualTiltAngle(viewCenter: CGPoint, screenCenter: CGPoint) -> CGFloat {
        // Tilt left if on left side, right if on right side
        return viewCenter.x < screenCenter.x
            ? CircularMenuConstants.Angles.tiltAngleLeft
            : CircularMenuConstants.Angles.tiltAngleRight
    }

    private func applyShadow(to view: UIView) {
        view.layer.shadowColor = configuration.shadowColor.cgColor
        view.layer.shadowOpacity = configuration.shadowOpacity
        view.layer.shadowOffset = configuration.shadowOffset
        view.layer.shadowRadius = configuration.shadowRadius
        view.layer.masksToBounds = false
    }

    private func animateHighlight() {
        guard highlightedSnapshotView != nil else { return }

        // Optional: Add initial state and animate in
        // Currently the snapshot is already in final state
        // You can add fade-in or other entrance animations here if needed
    }

    private func cleanup() {
        highlightedSnapshotView?.removeFromSuperview()
        highlightedSnapshotView = nil

        // Restore original view
        originalView?.alpha = 1

        originalView = nil
        containerView = nil
    }
}
