---
Guide ID: GUIDE-001
Version: 1.0.0
Last Updated: 2025-12-02
Related Contracts: [CONT-001, CONT-002, CONT-003, CONT-004, CONT-005]
Related Principles: [PRIN-001, PRIN-002, PRIN-003, PRIN-004]
---

# Feature 구현 가이드

새로운 Feature를 추가할 때 따라야 할 단계별 체크리스트입니다.

## 1. 사전 준비

### 요구사항 분석

- [ ] Feature의 책임과 범위가 명확한가?
- [ ] UI Mockup이 있는가?
- [ ] 데이터 모델을 정의했는가?
- [ ] 네비게이션 흐름을 파악했는가?

### Service 필요 여부 판단

다음 의사결정 트리를 따르세요:

```
Repository 1개만 사용?
├─ YES → Service 불필요 (Reactor에서 직접 Repository 호출)
└─ NO → 다음 질문으로

복잡한 비즈니스 로직이 있는가?
(검증, 변환, 조건 분기 등)
├─ YES → Service 필요
└─ NO → 다음 질문으로

여러 Repository를 조합하는가?
├─ YES → Service 필요
└─ NO → Service 불필요
```

**Service 필요한 경우**:
- 여러 Repository 조합
- 복잡한 데이터 검증/변환
- 10줄 이상의 비즈니스 로직

**Service 불필요한 경우**:
- Repository 1개만 사용
- 단순 CRUD 작업
- 로직이 5줄 이내

## 2. 파일 생성

### 디렉토리 구조

```
Features/
  {FeatureName}/
    Coordinator/
      {FeatureName}Coordinator.swift
    View/
      {FeatureName}ViewController.swift
      Components/
        {ComponentName}View.swift
    Reactor/
      {FeatureName}Reactor.swift
      {FeatureName}Service.swift  # Service 필요 시만
```

### 체크리스트

- [ ] Coordinator 파일 생성
- [ ] ViewController 파일 생성
- [ ] Reactor 파일 생성
- [ ] Service 파일 생성 (필요시)
- [ ] Components 디렉토리 생성 (복잡한 UI가 있으면)

## 3. Model 정의

### Realm Model (필요 시)

```swift
// Data/Models/Realm{Type}.swift
final class RealmBook: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var title: String
    @Persisted var createdAt: Date

    func toDTO() -> Book {
        return Book(id: id, title: title, createdAt: createdAt)
    }
}
```

### DTO Model

```swift
// Data/Models/{Type}.swift
struct Book {
    let id: String
    let title: String
    let createdAt: Date

    func toRealmModel() -> RealmBook {
        let realm = RealmBook()
        realm.id = id
        realm.title = title
        realm.createdAt = createdAt
        return realm
    }
}
```

### 체크리스트

- [ ] Realm 모델이 필요한가?
- [ ] `toDTO()` 메서드를 구현했는가?
- [ ] `toRealmModel()` 메서드를 구현했는가?
- [ ] DTO가 struct인가?

## 4. Repository 구현 (데이터 계층)

### Protocol 정의

```swift
protocol BookRepositoryProtocol {
    func getBook(id: String) -> Observable<RealmBook>
    func save(_ book: RealmBook) -> Observable<RealmBook>
}
```

### 구현

```swift
final class BookRepository: BaseRepository<RealmBook>, BookRepositoryProtocol {
    func getBook(id: String) -> Observable<RealmBook> {
        return findById(id)
    }

    func save(_ book: RealmBook) -> Observable<RealmBook> {
        return add(book)
    }
}
```

### 체크리스트

- [ ] [CONT-004 Repository 계약](../contracts/repository-contract.md) 준수
- [ ] Protocol 정의 완료
- [ ] BaseRepository 상속
- [ ] Observable 반환
- [ ] 비즈니스 로직 없음 (단순 CRUD만)

## 5. Service 구현 (비즈니스 로직)

**Service가 필요한 경우에만 진행**

### Protocol 정의

```swift
protocol BookDetailServiceProtocol {
    func loadBookDetail(bookId: String) -> Observable<BookDetail>
    func saveQuote(bookId: String, text: String) -> Observable<Quote>
}
```

### 구현

```swift
final class BookDetailService: BookDetailServiceProtocol {
    private let bookRepository: BookRepositoryProtocol
    private let quoteRepository: QuoteRepositoryProtocol

    init(serviceFactory: ServiceFactory) {
        self.bookRepository = serviceFactory.createBookRepository()
        self.quoteRepository = serviceFactory.createQuoteRepository()
    }

    func loadBookDetail(bookId: String) -> Observable<BookDetail> {
        return Observable.zip(
            bookRepository.getBook(id: bookId),
            quoteRepository.getQuotes(for: bookId)
        ).map { book, quotes in
            BookDetail(book: book.toDTO(), quotes: quotes.map { $0.toDTO() })
        }
    }
}
```

### 체크리스트

- [ ] [CONT-003 Service 계약](../contracts/service-contract.md) 준수
- [ ] Protocol 정의 완료
- [ ] Repository 조합
- [ ] DTO 변환 수행
- [ ] Observable 반환
- [ ] ServiceFactory 저장 안 함

## 6. Reactor 구현 (상태 관리)

### Action, Mutation, State 정의

```swift
final class BookDetailReactor: Reactor {
    enum Action {
        case load
        case save(String)
    }

    enum Mutation {
        case setBookDetail(BookDetail)
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
    }
}
```

### mutate 구현

```swift
func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .load:
        return loadMutation()

    case .save(let text):
        return service.saveQuote(bookId: currentState.bookId, text: text)
            .map { _ in .setLoading(false) }
            .catch { .just(.setError($0)) }
    }
}
```

### 체크리스트

- [ ] [CONT-001 Reactor 계약](../contracts/reactor-contract.md) 준수
- [ ] Action, Mutation, State 정의
- [ ] Service 주입 (또는 Repository 직접 사용)
- [ ] mutate()가 10줄 이하
- [ ] reduce()가 순수 함수
- [ ] NavigationEvent 정의

## 7. ViewController 구현 (UI 계층)

### UI 구성

```swift
final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        return tv
    }()

    override func setupUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
```

### Reactive Binding

```swift
override func bind(reactor: BookDetailReactor) {
    // Input
    saveButton.rx.tap
        .map { Reactor.Action.save }
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

    // Output
    reactor.state
        .map { $0.bookDetail }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: nil)
        .compactMap { $0 }
        .drive(onNext: { [weak self] detail in
            self?.updateUI(with: detail)
        })
        .disposed(by: disposeBag)
}
```

### 체크리스트

- [ ] [CONT-005 View 계약](../contracts/view-contract.md) 준수
- [ ] BaseViewController 상속
- [ ] setupUI() 구현
- [ ] bind(reactor:) 구현
- [ ] Driver 사용
- [ ] SnapKit으로 레이아웃
- [ ] Localized String 사용

## 8. Coordinator 구현 (네비게이션)

### 기본 구조

```swift
final class BookDetailCoordinator: BaseCoordinator {
    private weak var navigationController: UINavigationController?
    private let serviceFactory: ServiceFactory
    private let bookId: String

    func start() {
        let service = BookDetailService(serviceFactory: serviceFactory)
        let reactor = BookDetailReactor(service: service, bookId: bookId)
        let viewController = BookDetailViewController(reactor: reactor)

        reactor.navigationEvents
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigation(event)
            })
            .disposed(by: disposeBag)

        navigationController?.pushViewController(viewController, animated: true)
    }
}
```

### 체크리스트

- [ ] [CONT-002 Coordinator 계약](../contracts/coordinator-contract.md) 준수
- [ ] BaseCoordinator 상속
- [ ] start() 구현
- [ ] NavigationEvent 구독
- [ ] Child Coordinator 관리
- [ ] ServiceFactory 전달

## 9. ServiceFactory 등록

### Repository 생성 메서드 추가

```swift
extension ServiceFactory {
    func createBookRepository() -> BookRepositoryProtocol {
        if let cached = getCachedService(BookRepositoryProtocol.self) {
            return cached
        }
        let repository = BookRepository()
        cacheService(repository, for: BookRepositoryProtocol.self)
        return repository
    }
}
```

### 체크리스트

- [ ] Repository 생성 메서드 추가
- [ ] 캐싱 구현
- [ ] Protocol 타입 반환

## 10. 통합 및 테스트

### 통합 체크리스트

- [ ] 빌드 성공
- [ ] 컴파일 에러 없음
- [ ] 경고(Warning) 없음

### 기능 테스트

- [ ] 화면 진입 가능
- [ ] 데이터 로딩 동작
- [ ] 사용자 상호작용 동작
- [ ] 네비게이션 동작
- [ ] 에러 처리 동작

### 메모리 테스트

- [ ] 메모리 누수 없음 (Instruments 확인)
- [ ] DisposeBag 정리 확인
- [ ] Coordinator 정리 확인

## 11. Code Review 준비

### 자가 검증

- [ ] [검증 체크리스트](validation-checklist.md) 실행
- [ ] 모든 Contract 준수 확인
- [ ] 코드 스타일 일관성 확인

### 문서화

- [ ] 복잡한 로직에 주석 추가
- [ ] Public API에 문서 주석 추가
- [ ] Localization Key 추가

## 의사결정 가이드

### Service vs Repository 직접 사용

```
┌─ Repository 1개만 사용
│  └─ Reactor에서 Repository 직접 호출 ✅
│
├─ Repository 2개 이상 조합
│  └─ Service 생성 ✅
│
├─ 복잡한 검증/변환 로직 (10줄 이상)
│  └─ Service 생성 ✅
│
└─ 단순 CRUD (5줄 이내)
   └─ Reactor에서 Repository 직접 호출 ✅
```

### Custom Component vs 기본 UIKit

```
┌─ 재사용 가능한 UI (3곳 이상 사용)
│  └─ Common/UI/Components에 생성 ✅
│
├─ Feature 전용 복잡한 UI
│  └─ Features/{Name}/View/Components에 생성 ✅
│
└─ 단순한 UI (UILabel, UIButton 조합)
   └─ ViewController에 직접 생성 ✅
```

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-003](../principles/immutable-state.md) - 상태 불변성
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-001](../contracts/reactor-contract.md) - Reactor 계약
- [CONT-002](../contracts/coordinator-contract.md) - Coordinator 계약
- [CONT-003](../contracts/service-contract.md) - Service 계약
- [CONT-004](../contracts/repository-contract.md) - Repository 계약
- [CONT-005](../contracts/view-contract.md) - View 계약

**가이드**:
- [GUIDE-002](data-flow-checklist.md) - 데이터 흐름 체크리스트
- [GUIDE-003](state-management-guide.md) - State 관리 가이드
- [GUIDE-005](validation-checklist.md) - 검증 체크리스트
