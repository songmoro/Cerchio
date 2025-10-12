//
//  QuoteShareReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import Foundation
import ReactorKit
import RxSwift

final class QuoteShareReactor: Reactor {
    enum Action {
        case dismissTapped
        case saveTapped
        case backgroundToggled(Bool)
        case blurIntensityChanged(CGFloat)
    }

    enum Mutation {
        case setBackgroundEnabled(Bool)
        case setBlurIntensity(CGFloat)
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

        case .blurIntensityChanged(let intensity):
            return .just(.setBlurIntensity(intensity))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.shouldExportImage = false
        newState.shouldDismiss = false

        switch mutation {
        case .setBackgroundEnabled(let isEnabled):
            newState.backgroundConfig.isEnabled = isEnabled

        case .setBlurIntensity(let intensity):
            newState.backgroundConfig.blurIntensity = intensity

        case .exportImage:
            newState.shouldExportImage = true

        case .dismiss:
            newState.shouldDismiss = true
        }

        return newState
    }
}
