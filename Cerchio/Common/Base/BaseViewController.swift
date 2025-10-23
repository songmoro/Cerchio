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
import FirebaseAnalytics

protocol NavigationEventEmittable {
    var navigationEvents: PublishRelay<NavigationEvent> { get }
}

protocol BaseViewControllerType: UIViewController, NavigationEventEmittable {
    associatedtype ReactorType: Reactor

    var disposeBag: DisposeBag { get set }
    var coordinator: Coordinator? { get set }

    func setupUI()
    func bind(reactor: ReactorType)
}

class BaseViewController<T: Reactor>: UIViewController, BaseViewControllerType, View {
    typealias ReactorType = T

    var disposeBag = DisposeBag()
    weak var coordinator: Coordinator?
    let navigationEvents = PublishRelay<NavigationEvent>()

    private var isFinishing = false

    var reactor: T? {
        didSet {
            guard let reactor = reactor else { return }

            if isViewLoaded {
                self.bind(reactor: reactor)
            } else {
                shouldBindAfterViewDidLoad = true
            }
        }
    }

    private var shouldBindAfterViewDidLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindNavigationEvents()

        if shouldBindAfterViewDidLoad, let reactor = reactor {
            self.bind(reactor: reactor)
            shouldBindAfterViewDidLoad = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            isFinishing = true
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isFinishing {
            coordinator?.finish()
            isFinishing = false
        }
    }

    func setupUI() {
        view.backgroundColor = .white
        setupNavigationBarAppearance()
    }

    private func setupNavigationBarAppearance() {
        guard let navigationController = navigationController else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.forestGreen]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.forestGreen]

        let navigationBar = navigationController.navigationBar
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        navigationBar.tintColor = .forestGreen
    }

    func bind(reactor: T) {
        fatalError("Must be overridden")
    }

    private func bindNavigationEvents() {
        navigationEvents
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .back:
                    self?.navigationController?.popViewController(animated: true)
                case .close:
                    self?.dismiss(animated: true)
                case .finished:
                    self?.coordinator?.finish()
                }
            })
            .disposed(by: disposeBag)
    }

    func emitNavigationEvent(_ event: NavigationEvent) {
        navigationEvents.accept(event)
    }

    private func logScreenView() {
        let screenName = String(describing: type(of: self))
            .replacingOccurrences(of: "ViewController", with: "")

        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: String(describing: type(of: self))
        ])
    }

    deinit {
    }
}
