//
//  BaseViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa

class BaseViewController<T: Reactor>: UIViewController, View {
    var disposeBag = DisposeBag()
    let navigationEvents = PublishRelay<Any>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Automatic cleanup when view controller is dismissed
        if isBeingDismissed || isMovingFromParent {
            // Notify parent coordinator for cleanup
            navigationEvents.accept(ViewControllerDismissedEvent())
        }
    }

    // MARK: - Abstract Methods
    func setupUI() {
        // Override in subclasses
    }

    func bind(reactor: T) {
        // Override in subclasses
    }

    deinit {
        print("✅ \(String(describing: type(of: self))) deinit")
    }
}

struct ViewControllerDismissedEvent {
    // Event to notify coordinator when view controller is dismissed
}