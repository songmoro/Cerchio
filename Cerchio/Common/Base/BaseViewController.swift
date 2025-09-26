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

// MARK: - Navigation Event Emittable Protocol
protocol NavigationEventEmittable {
    var navigationEvents: PublishRelay<NavigationEvent> { get }
}

// MARK: - Base View Controller Protocol
protocol BaseViewControllerType: UIViewController, NavigationEventEmittable {
    associatedtype ReactorType: Reactor

    var disposeBag: DisposeBag { get set }
    var coordinator: Coordinator? { get set }

    func setupUI()
    func bind(reactor: ReactorType)
}

// MARK: - Base View Controller
class BaseViewController<T: Reactor>: UIViewController, BaseViewControllerType, View {
    typealias ReactorType = T

    var disposeBag = DisposeBag()
    weak var coordinator: Coordinator?
    let navigationEvents = PublishRelay<NavigationEvent>()

    private var isFinishing = false

    // ReactorKit View Protocol Implementation
    var reactor: T? {
        didSet {
            guard let reactor = reactor else { return }

            // 뷰가 로드된 후에만 bind 호출
            if isViewLoaded {
                self.bind(reactor: reactor)
            } else {
                // 뷰가 아직 로드되지 않았다면 viewDidLoad에서 호출하도록 플래그 설정
                shouldBindAfterViewDidLoad = true
            }
        }
    }

    private var shouldBindAfterViewDidLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindNavigationEvents()

        // reactor가 이미 설정되어 있다면 bind 호출
        if shouldBindAfterViewDidLoad, let reactor = reactor {
            self.bind(reactor: reactor)
            shouldBindAfterViewDidLoad = false
        }
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

    // MARK: - Abstract Methods
    func setupUI() {
        view.backgroundColor = .systemBackground
    }

    func bind(reactor: T) {
        fatalError("Must be overridden")
    }

    // MARK: - Navigation Events
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

    deinit {
        print("✅ \(String(describing: type(of: self))) deinit")
    }
}
