//
//  QuoteShareReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import Foundation
import UIKit
import ReactorKit
import RxSwift

final class QuoteShareReactor: Reactor {
    enum Action {
        case dismissTapped
        case saveTapped
        case backgroundToggled(Bool)
        case blurChanged(isEnabled: Bool, intensity: CGFloat)
        case blurColorChanged(isEnabled: Bool, color: UIColor, opacity: CGFloat)
        case opacityChanged(isEnabled: Bool, opacity: CGFloat)
        case scaleChanged(isEnabled: Bool, scale: CGFloat)
    }

    enum Mutation {
        case setBackgroundEnabled(Bool)
        case setBlur(isEnabled: Bool, intensity: CGFloat)
        case setBlurColor(isEnabled: Bool, color: UIColor, opacity: CGFloat)
        case setOpacity(isEnabled: Bool, opacity: CGFloat)
        case setScale(isEnabled: Bool, scale: CGFloat)
        case exportImage
        case dismiss
    }

    struct State {
        let quoteData: QuoteShareData
        var backgroundConfig: QuoteBackgroundConfig
        var shouldExportImage: Bool = false
        var shouldDismiss: Bool = false
    }

    let initialState: State

    init(quoteData: QuoteShareData) {
        self.initialState = State(
            quoteData: quoteData,
            backgroundConfig: quoteData.backgroundConfig
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .dismissTapped:
            return .just(.dismiss)

        case .saveTapped:
            return .just(.exportImage)

        case .backgroundToggled(let isEnabled):
            return .just(.setBackgroundEnabled(isEnabled))

        case .blurChanged(let isEnabled, let intensity):
            return .just(.setBlur(isEnabled: isEnabled, intensity: intensity))

        case .blurColorChanged(let isEnabled, let color, let opacity):
            return .just(.setBlurColor(isEnabled: isEnabled, color: color, opacity: opacity))

        case .opacityChanged(let isEnabled, let opacity):
            return .just(.setOpacity(isEnabled: isEnabled, opacity: opacity))

        case .scaleChanged(let isEnabled, let scale):
            return .just(.setScale(isEnabled: isEnabled, scale: scale))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.shouldExportImage = false
        newState.shouldDismiss = false

        switch mutation {
        case .setBackgroundEnabled(let isEnabled):
            newState.backgroundConfig.isEnabled = isEnabled

        case .setBlur(let isEnabled, let intensity):
            newState.backgroundConfig.isBlurEnabled = isEnabled
            newState.backgroundConfig.blurIntensity = intensity

        case .setBlurColor(let isEnabled, let color, let opacity):
            newState.backgroundConfig.isBlurColorEnabled = isEnabled
            newState.backgroundConfig.blurColor = color
            newState.backgroundConfig.blurColorOpacity = opacity

        case .setOpacity(let isEnabled, let opacity):
            newState.backgroundConfig.isOpacityEnabled = isEnabled
            newState.backgroundConfig.imageOpacity = opacity

        case .setScale(let isEnabled, let scale):
            newState.backgroundConfig.isScaleEnabled = isEnabled
            newState.backgroundConfig.imageScale = scale

        case .exportImage:
            newState.shouldExportImage = true

        case .dismiss:
            newState.shouldDismiss = true
        }

        return newState
    }
}
