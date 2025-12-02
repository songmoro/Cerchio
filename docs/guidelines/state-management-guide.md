---
Guide ID: GUIDE-003
Version: 1.0.0
Last Updated: 2025-12-02
Related Principles: [PRIN-001, PRIN-003]
Related Contracts: [CONT-001]
---

# State 관리 가이드

Reactor의 State를 효과적으로 설계하고 관리하는 방법을 설명합니다.

## State 설계 원칙

### 1. 불변성 (Immutability)

State는 반드시 `struct`로 정의:

```swift
// ✅ 준수
struct State {
    var bookDetail: BookDetail?
    var isLoading: Bool = false
}

// ❌ 위반
class State {
    var bookDetail: BookDetail?
    var isLoading: Bool = false
}
```

### 2. 단일 진실의 원천 (Single Source of Truth)

모든 UI 관련 데이터는 State에 저장:

```swift
// ✅ 준수
struct State {
    var books: [Book] = []
    var selectedBook: Book?
    var isLoading: Bool = false
    var error: Error?
}

// View에서
reactor.state.map { $0.books }
    .asDriver(onErrorJustReturn: [])
    .drive(tableView.rx.items(...))

// ❌ 위반
class ViewController {
    var books: [Book] = [] // ❌ ViewController에 저장
    var reactor: Reactor!
}
```

## Derived State vs Stored State

### Stored State (저장된 상태)

State에 직접 저장해야 하는 데이터:

```swift
struct State {
    // ✅ 원본 데이터
    var books: [Book] = []
    var selectedBookId: String?

    // ✅ 서버에서 받은 데이터
    var bookDetail: BookDetail?

    // ✅ UI 상태
    var isLoading: Bool = false
    var error: Error?
}
```

### Derived State (파생된 상태)

계산 가능한 데이터는 State에 저장하지 않음:

```swift
struct State {
    var books: [Book] = []

    // ❌ 위반: 파생 데이터를 State에 저장
    var bookCount: Int = 0

    // ✅ 준수: computed property 또는 View에서 계산
}

// View에서 계산
reactor.state
    .map { $0.books.count }
    .asDriver(onErrorJustReturn: 0)
    .drive(countLabel.rx.text)
```

### 판단 기준

```
State에 저장해야 하는가?

├─ 서버에서 받은 원본 데이터? → YES (저장)
├─ 사용자 입력? → YES (저장)
├─ 로딩/에러 상태? → YES (저장)
├─ 다른 State 값으로 계산 가능? → NO (View에서 계산)
└─ 단순 포맷팅? → NO (View에서 처리)
```

## State 최적화

### 1. Equatable 구현

중복 업데이트 방지를 위해 Equatable 구현:

```swift
struct BookDetail: Equatable {
    let book: Book
    let quotes: [Quote]

    static func == (lhs: BookDetail, rhs: BookDetail) -> Bool {
        return lhs.book.id == rhs.book.id &&
               lhs.quotes.count == rhs.quotes.count
    }
}

struct State {
    var bookDetail: BookDetail?
}

// View에서
reactor.state
    .map { $0.bookDetail }
    .distinctUntilChanged() // Equatable이 있어야 작동
    .asDriver(onErrorJustReturn: nil)
    .drive(...)
```

### 2. 세분화된 구독

필요한 데이터만 구독:

```swift
// ✅ 준수: 필요한 것만 구독
reactor.state
    .map { $0.bookDetail?.title }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: "")
    .drive(titleLabel.rx.text)

reactor.state
    .map { $0.isLoading }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: false)
    .drive(loadingIndicator.rx.isAnimating)

// ❌ 위반: 전체 State 구독
reactor.state
    .asDriver(onErrorJustReturn: initialState)
    .drive(onNext: { [weak self] state in
        self?.titleLabel.text = state.bookDetail?.title
        self?.loadingIndicator.isAnimating = state.isLoading
    })
```

### 3. 중첩된 State 분리

복잡한 State는 nested struct로 분리:

```swift
// ✅ 준수
struct State {
    var content: Content = Content()
    var ui: UIState = UIState()
    var loading: LoadingState = LoadingState()

    struct Content {
        var bookDetail: BookDetail?
        var quotes: [Quote] = []
    }

    struct UIState {
        var selectedTab: Tab = .quotes
        var searchText: String = ""
    }

    struct LoadingState {
        var isLoadingBook: Bool = false
        var isLoadingQuotes: Bool = false
    }
}

// View에서
reactor.state
    .map { $0.content.bookDetail }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: nil)
    .drive(...)
```

## 일반적인 State 패턴

### 1. 로딩 상태

```swift
struct State {
    var isLoading: Bool = false
    var data: [Item]?
    var error: Error?
}

// Mutation
enum Mutation {
    case setLoading(Bool)
    case setData([Item])
    case setError(Error)
}

// reduce
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    newState.error = nil // 새 작업 시작 시 에러 초기화

    switch mutation {
    case .setLoading(let isLoading):
        newState.isLoading = isLoading

    case .setData(let data):
        newState.data = data
        newState.isLoading = false

    case .setError(let error):
        newState.error = error
        newState.isLoading = false
    }

    return newState
}
```

### 2. 페이지네이션

```swift
struct State {
    var items: [Item] = []
    var currentPage: Int = 0
    var hasMore: Bool = true
    var isLoadingMore: Bool = false
}

// Mutation
enum Mutation {
    case appendItems([Item], hasMore: Bool)
    case setLoadingMore(Bool)
}

// reduce
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state

    switch mutation {
    case .appendItems(let items, let hasMore):
        newState.items.append(contentsOf: items)
        newState.currentPage += 1
        newState.hasMore = hasMore
        newState.isLoadingMore = false

    case .setLoadingMore(let isLoading):
        newState.isLoadingMore = isLoading
    }

    return newState
}
```

### 3. 선택 상태

```swift
struct State {
    var items: [Item] = []
    var selectedItemIds: Set<String> = []

    // Derived state (computed property 가능)
    var selectedItems: [Item] {
        items.filter { selectedItemIds.contains($0.id) }
    }
}

// Mutation
enum Mutation {
    case toggleSelection(String)
    case clearSelection
}

// reduce
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state

    switch mutation {
    case .toggleSelection(let id):
        if newState.selectedItemIds.contains(id) {
            newState.selectedItemIds.remove(id)
        } else {
            newState.selectedItemIds.insert(id)
        }

    case .clearSelection:
        newState.selectedItemIds.removeAll()
    }

    return newState
}
```

### 4. 폼 상태

```swift
struct State {
    var title: String = ""
    var author: String = ""
    var pageCount: String = ""

    var isValid: Bool {
        !title.isEmpty && !author.isEmpty && Int(pageCount) != nil
    }
}

// View에서
Observable.combineLatest(
    titleField.rx.text.orEmpty,
    authorField.rx.text.orEmpty,
    pageField.rx.text.orEmpty
)
.map { Reactor.Action.updateForm(title: $0, author: $1, pageCount: $2) }
.bind(to: reactor.action)
.disposed(by: disposeBag)

reactor.state
    .map { $0.isValid }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: false)
    .drive(saveButton.rx.isEnabled)
    .disposed(by: disposeBag)
```

## State 초기화 패턴

### 1. 기본값 초기화

```swift
struct State {
    var books: [Book] = []
    var isLoading: Bool = false
    var selectedTab: Tab = .list
}

let initialState = State()
```

### 2. 파라미터 초기화

```swift
struct State {
    let bookId: String // 불변 파라미터
    var bookDetail: BookDetail?
    var isLoading: Bool = false
}

init(bookId: String) {
    self.initialState = State(bookId: bookId)
}
```

### 3. Factory 메서드

```swift
struct State {
    var books: [Book]
    var filter: Filter

    static func initial(with filter: Filter) -> State {
        return State(books: [], filter: filter)
    }
}

let initialState = State.initial(with: .favorites)
```

## 안티패턴

### 1. Realm 객체를 State에 저장

```swift
// ❌ 위반
struct State {
    var realmBook: RealmBook? // ❌ Thread-confined
}

// ✅ 준수
struct State {
    var book: Book? // DTO 사용
}
```

### 2. Class 타입을 State에 저장

```swift
// ❌ 위반
struct State {
    var viewModel: BookViewModel // ❌ Reference type
}

// ✅ 준수
struct State {
    var book: Book // Value type
}
```

### 3. State에서 부작용 수행

```swift
// ❌ 위반
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .dataSaved:
        print("Saved!") // ❌ 부작용
        UserDefaults.standard.set(true, forKey: "saved") // ❌ 부작용
    }
    return newState
}

// ✅ 준수
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .dataSaved:
        newState.isSaved = true // State 변경만
    }
    return newState
}
```

### 4. 파생 데이터 중복 저장

```swift
// ❌ 위반
struct State {
    var books: [Book] = []
    var bookCount: Int = 0 // ❌ 중복 (books.count와 동일)
    var isEmpty: Bool = true // ❌ 중복 (books.isEmpty와 동일)
}

// ✅ 준수
struct State {
    var books: [Book] = []
}

// View에서 계산
reactor.state
    .map { $0.books.count }
    .asDriver(onErrorJustReturn: 0)
    .drive(countLabel.rx.text)
```

## 체크리스트

### State 설계

- [ ] State가 struct인가?
- [ ] 모든 UI 데이터가 State에 있는가?
- [ ] Realm 객체가 없는가?
- [ ] Class 타입이 없는가?
- [ ] 파생 데이터를 중복 저장하지 않는가?

### State 최적화

- [ ] Equatable을 구현했는가?
- [ ] 세분화된 구독을 사용하는가?
- [ ] distinctUntilChanged()를 사용하는가?
- [ ] 복잡한 State는 분리했는가?

### reduce() 검증

- [ ] 순수 함수인가? (부작용 없음)
- [ ] 새로운 State를 반환하는가?
- [ ] 원본 State를 변경하지 않는가?

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [PRIN-003](../principles/immutable-state.md) - 상태 불변성

**계약**:
- [CONT-001](../contracts/reactor-contract.md) - Reactor 계약

**가이드**:
- [GUIDE-001](feature-implementation.md) - Feature 구현 가이드
- [GUIDE-002](data-flow-checklist.md) - 데이터 흐름 체크리스트
