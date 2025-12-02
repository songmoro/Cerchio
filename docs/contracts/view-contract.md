---
Contract ID: CONT-005
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Principles: [PRIN-001, PRIN-002, PRIN-004]
---

# View 계약

## 계약 정의

View는 **UI 렌더링과 이벤트 캡처만 담당**하며, 비즈니스 로직과 데이터 접근을 수행하지 않는다.

```
View = UI Rendering + Event Capture
```

## 필수 책임 (Must)

### 1. Action 발행

View는 반드시 사용자 이벤트를 Action으로 변환해야 함:

```
User Event → Action → Reactor
```

### 2. State 구독

- State 변경사항 구독
- Driver를 사용한 UI 업데이트
- Main Thread 보장
- 자동 메모리 관리 (DisposeBag)

### 3. UI 구성

- `setupUI()`: View 계층 구조 생성
- SnapKit으로 Auto Layout 설정
- Custom UI Component 조합
- Accessibility 설정

### 4. Reactive Binding

- `bind(reactor:)`: Reactor와 양방향 바인딩
- Input: Button tap, TextField text 등
- Output: State → UI 업데이트
- `.disposed(by: disposeBag)` 필수

## 금지사항 (Must Not)

### 1. 비즈니스 로직 구현 금지

```
❌ 데이터 검증 (Reactor/Service가 담당)
❌ 데이터 변환
❌ 복잡한 조건 분기 (UI 상태 외)
```

### 2. 직접 데이터 접근 금지

```
❌ import RealmSwift
❌ Repository 참조
❌ Database 직접 접근
❌ UserDefaults 직접 사용 (State를 통해야 함)
```

### 3. Reactor State 직접 변경 금지

```
❌ reactor.currentState.someValue = newValue
❌ reactor.action.onNext(.someAction) // bind(to:) 사용
```

대신 reactive binding 사용:
```swift
// ✅ 준수
button.rx.tap
    .map { Reactor.Action.buttonTapped }
    .bind(to: reactor.action)
    .disposed(by: disposeBag)

// ❌ 위반
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
@objc func buttonTapped() {
    reactor.action.onNext(.buttonTapped)
}
```

### 4. 네비게이션 직접 수행 금지

```
❌ navigationController?.pushViewController(...)
❌ present(..., animated: true)
```

대신 NavigationEvent 발행:
```swift
// View에서
reactor.navigationEvents
    .emit(to: navigationEvents)
    .disposed(by: disposeBag)

// Coordinator가 구독
viewController.navigationEvents
    .subscribe(onNext: { [weak self] event in
        self?.handleNavigation(event)
    })
    .disposed(by: disposeBag)
```

## 구현 체크리스트

### 기본 구조

- [ ] `BaseViewController<T: Reactor>`를 상속했는가?
- [ ] `setupUI()` 메서드를 구현했는가?
- [ ] `bind(reactor:)` 메서드를 구현했는가?
- [ ] `DisposeBag`을 선언했는가?

### UI 구성

- [ ] SnapKit으로 레이아웃을 설정했는가?
- [ ] UI 컴포넌트가 private/lazy var인가?
- [ ] Custom Font를 사용하는가? (`.customFont(...)`)
- [ ] Localized String을 사용하는가?

### Reactive Binding

- [ ] Input binding이 명확한가? (Button → Action)
- [ ] Output binding이 Driver를 사용하는가?
- [ ] `[weak self]`를 사용하는가?
- [ ] `.disposed(by: disposeBag)`을 호출하는가?

### State 구독

- [ ] State 변경에만 반응하는가?
- [ ] `.distinctUntilChanged()`를 사용하는가?
- [ ] Main Thread에서 UI를 업데이트하는가?

### 의존성 검증

- [ ] `import RealmSwift`가 없는가?
- [ ] Repository를 import하지 않는가?
- [ ] ServiceFactory를 참조하지 않는가?
- [ ] Reactor만 의존하는가?

### 파일 크기

- [ ] 파일 길이가 300줄 이하인가?
- [ ] bind(reactor:) 메서드가 50줄 이하인가?
- [ ] setupUI() 메서드가 100줄 이하인가?

## 코드 검증

### 자동 검증 스크립트

```bash
# 1. RealmSwift import 검증
grep "import RealmSwift" Features/*/View/*ViewController.swift
# 결과 없어야 함

# 2. Repository import 검증
grep "Repository" Features/*/View/*ViewController.swift | grep "import"
# 결과 없어야 함

# 3. BaseViewController 상속 검증
grep "BaseViewController" Features/*/View/*ViewController.swift
# 모든 ViewController가 상속해야 함

# 4. bind(reactor:) 메서드 존재 검증
grep "func bind(reactor:" Features/*/View/*ViewController.swift
# 모든 ViewController에 존재해야 함
```

### 수동 검증 (Code Review)

Pull Request 체크리스트:

**기본 구조**:
- [ ] ViewController 파일 이름이 `{Feature}ViewController.swift` 형식인가?
- [ ] BaseViewController를 상속하는가?

**원칙 준수**:
- [ ] [PRIN-001 단방향 데이터 흐름](../principles/unidirectional-data-flow.md) 준수
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md) 준수
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md) 준수

**코드 품질**:
- [ ] UI 로직만 포함하는가?
- [ ] Reactive binding이 명확한가?
- [ ] Driver를 적절히 사용하는가?

## 준수 예시

```swift
import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(QuoteCell.self, forCellReuseIdentifier: "QuoteCell")
        return tv
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: .save)
        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - Setup UI
    override func setupUI() {
        view.addSubview(tableView)
        view.addSubview(saveButton)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }
    }

    // MARK: - Bind
    override func bind(reactor: BookDetailReactor) {
        // Input: Button tap → Action
        saveButton.rx.tap
            .map { Reactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Output: State → UI
        reactor.state
            .map { $0.quotes }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "QuoteCell", cellType: QuoteCell.self)) { index, quote, cell in
                cell.configure(with: quote)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        // NavigationEvent
        reactor.navigationEvents
            .emit(to: navigationEvents)
            .disposed(by: disposeBag)
    }
}
```

## 위반 예시

```swift
import UIKit
import ReactorKit
import RxSwift
import RealmSwift // ❌ Database import

final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    // ❌ Repository 참조
    private let quoteRepository: QuoteRepository

    // ❌ 비즈니스 로직 저장
    private var validatedQuotes: [Quote] = []

    override func bind(reactor: BookDetailReactor) {
        // ❌ 비즈니스 로직 (검증)
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                // ❌ 데이터 검증 (Reactor가 해야 함)
                let text = self.textField.text ?? ""
                guard !text.isEmpty else {
                    self.showAlert(message: "텍스트를 입력하세요")
                    return
                }

                // ❌ 데이터 변환 (Service가 해야 함)
                let trimmed = text.trimmingCharacters(in: .whitespaces)

                // ❌ Repository 직접 호출
                let realm = try! Realm()
                let quote = RealmQuote()
                quote.text = trimmed

                try! realm.write {
                    realm.add(quote)
                }

                // ❌ State 직접 변경
                reactor.currentState.quotes.append(quote.toDTO())

                // ❌ 네비게이션 직접 수행
                let successVC = SuccessViewController()
                self.navigationController?.present(successVC, animated: true)
            })
            .disposed(by: disposeBag)

        // ❌ subscribe 사용 (Driver 사용해야 함)
        reactor.state
            .map { $0.quotes }
            .subscribe(onNext: { [weak self] quotes in
                // ❌ 비즈니스 로직 (필터링)
                self?.validatedQuotes = quotes.filter { $0.text.count > 10 }

                // UI 업데이트
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    // ❌ 복잡한 비즈니스 로직
    private func validateAndSave(text: String) {
        // 30줄의 검증 로직...
    }

    // ❌ Alert (간단한 것만 허용)
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        present(alert, animated: true)
    }
}
```

## 위반 시 수정 방법

### 문제: 비즈니스 로직 포함

**Before (위반)**:
```swift
saveButton.rx.tap
    .subscribe(onNext: { [weak self] in
        let text = self?.textField.text ?? ""
        guard !text.isEmpty else { return } // ❌ 검증
        let trimmed = text.trimmingCharacters(in: .whitespaces) // ❌ 변환
        reactor.action.onNext(.save(trimmed))
    })
    .disposed(by: disposeBag)
```

**After (계약 준수)**:
```swift
// View: 이벤트만 전달
saveButton.rx.tap
    .withLatestFrom(textField.rx.text.orEmpty)
    .map { Reactor.Action.save($0) }
    .bind(to: reactor.action)
    .disposed(by: disposeBag)

// Reactor/Service: 검증 및 변환 담당
func mutate(action: Action) -> Observable<Mutation> {
    case .save(let text):
        return service.saveQuote(text: text) // Service가 검증/변환
            .map { .quoteSaved }
}
```

### 문제: subscribe 대신 Driver 사용

**Before (위반)**:
```swift
reactor.state
    .map { $0.quotes }
    .subscribe(onNext: { [weak self] quotes in
        self?.tableView.reloadData()
    })
    .disposed(by: disposeBag)
```

**After (계약 준수)**:
```swift
reactor.state
    .map { $0.quotes }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: [])
    .drive(tableView.rx.items(...)) { ... }
    .disposed(by: disposeBag)
```

### 문제: Repository 직접 접근

**Before (위반)**:
```swift
class BookDetailViewController {
    let repository: BookRepository // ❌

    func saveQuote() {
        let realm = try! Realm()
        // ...
    }
}
```

**After (계약 준수)**:
```swift
class BookDetailViewController {
    // Repository 참조 없음
    // Reactor를 통해서만 데이터 접근

    override func bind(reactor: BookDetailReactor) {
        saveButton.rx.tap
            .map { Reactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}
```

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-001](reactor-contract.md) - Reactor 계약
- [CONT-002](coordinator-contract.md) - Coordinator 계약

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md) - Feature 구현 가이드
