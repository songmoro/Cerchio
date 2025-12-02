---
Principle ID: PRIN-004
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Documents: [PRIN-001, PRIN-003]
---

# 반응형 프로그래밍 원칙

## 원칙 정의

모든 비동기 데이터 흐름은 Observable 스트림으로 표현되며, 상태 변화에 자동으로 반응한다.

```
Data Flow = Observable Stream
UI Update = State Observation
```

## 문제 배경 (Why)

### 명령형 상태 동기화의 문제

**1. 수동 상태 동기화**
```swift
// 명령형 방식
var items: [Item] = []

func loadItems() {
    API.fetch { result in
        self.items = result
        self.tableView.reloadData() // 수동 업데이트
        self.emptyView.isHidden = !result.isEmpty // 수동 업데이트
        self.countLabel.text = "\(result.count)" // 수동 업데이트
    }
}

// 문제:
// - 상태와 UI가 따로 관리됨
// - 업데이트 누락 가능
// - 동기화 시점 제어 어려움
```

**2. Callback Hell**
```swift
API.fetchBooks { books in
    API.fetchQuotes(for: books[0].id) { quotes in
        API.fetchTags(for: books[0].id) { tags in
            // 중첩된 콜백
            // 에러 처리 복잡
            // 취소 불가능
        }
    }
}
```

**3. 메모리 누수**
```swift
class MyViewController {
    var callback: ((Data) -> Void)?

    func loadData() {
        API.fetch { [weak self] data in
            self?.callback?(data) // weak self 빠뜨리기 쉬움
        }
    }
}
```

**4. 상태 불일치**
```swift
var isLoading = false
var data: [Item] = []

func load() {
    isLoading = true
    API.fetch { result in
        data = result
        // isLoading = false 누락 → UI가 계속 로딩 표시
    }
}
```

### 반응형 프로그래밍특성

**1. 자동 상태 동기화**
```swift
// State
var items: [Item] = []

// UI는 State를 관찰
state.map { $0.items }
    .bind(to: tableView.rx.items)

state.map { $0.items.isEmpty }
    .bind(to: emptyView.rx.isHidden)

// State 변경 시 UI 자동 업데이트
```

**2. 선언적 데이터 흐름**
```swift
API.fetchBooks()
    .flatMap { books in API.fetchQuotes(for: books[0].id) }
    .flatMap { quotes in API.fetchTags(for: quotes.bookId) }
    .subscribe(onNext: { tags in
        // 완료
    })
```

**3. 자동 메모리 관리**
```swift
observable
    .subscribe(onNext: { data in
        // DisposeBag이 자동으로 메모리 해제
    })
    .disposed(by: disposeBag)
```

**4. 일관된 상태**
```swift
Observable.concat([
    .just(.setLoading(true)),
    service.fetch().map { .setData($0) },
    .just(.setLoading(false))
])
// 순서 보장, 누락 불가능
```

## 제약조건 (Constraints)

### 1. 비동기 작업은 Observable

**필수**:
```swift
// Repository
func fetch() -> Observable<[Item]> {
    return Observable.create { observer in
        // 비동기 작업
        observer.onNext(items)
        observer.onCompleted()
        return Disposables.create()
    }
}

// Service
func loadData() -> Observable<Data> {
    return repository.fetch()
        .map { items in Data(from: items) }
}
```

**금지**:
```swift
// ❌ Callback
func fetch(completion: @escaping ([Item]) -> Void) {
    // 콜백은 금지
}

// ❌ Synchronous
func fetch() -> [Item] {
    // 동기 방식은 금지
}
```

### 2. State 변화는 Observable

**필수**:
```swift
// Reactor State
reactor.state
    .map { $0.items }
    .subscribe(onNext: { items in
        // State 변화 자동 감지
    })
```

**금지**:
```swift
// ❌ 수동 폴링
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    if reactor.currentState.items != oldItems {
        updateUI()
    }
}
```

### 3. DisposeBag 사용

**필수**:
```swift
observable
    .subscribe(onNext: { data in })
    .disposed(by: disposeBag)
```

**금지**:
```swift
// ❌ Dispose 누락
observable.subscribe(onNext: { data in })
// 메모리 누수 발생
```

### 4. Main Thread 보장 (UI 업데이트)

**필수**:
```swift
reactor.state
    .map { $0.title }
    .asDriver(onErrorJustReturn: "")
    .drive(titleLabel.rx.text)
    .disposed(by: disposeBag)
```

**허용 (수동 관리)**:
```swift
reactor.state
    .map { $0.title }
    .observe(on: MainScheduler.instance)
    .subscribe(onNext: { title in
        titleLabel.text = title
    })
```

## 코드 검증

### 자동 검증 (CI 가능)

**1. Callback 패턴 검출**
```bash
# completion 파라미터가 있는 함수 검색
grep -r "completion: @escaping" Features/

# 발견 시 Observable로 변경 권장
```

**2. disposed(by:) 누락 검출**
```bash
# subscribe 후 disposed가 없는 경우 검출
# (SwiftLint 규칙으로 추가 가능)
```

### 수동 검증 (Code Review)

**Observable 사용 체크리스트**:
- [ ] 모든 비동기 작업이 Observable을 반환하는가?
- [ ] Callback 패턴을 사용하지 않는가?
- [ ] 모든 subscribe에 disposed(by:)가 있는가?

**UI 바인딩 체크리스트**:
- [ ] UI 업데이트에 asDriver 또는 observe(on: MainScheduler)를 사용하는가?
- [ ] 수동 UI 업데이트 (label.text = ...) 대신 바인딩을 사용하는가?
- [ ] distinctUntilChanged()로 불필요한 업데이트를 방지하는가?

### 준수 예시

**Observable 반환**:
```swift
// Repository
func getBooks() -> Observable<[RealmBook]> {
    return Observable.create { observer in
        let realm = try Realm()
        let books = realm.objects(RealmBook.self)
        observer.onNext(Array(books))
        observer.onCompleted()
        return Disposables.create()
    }
}

// Service
func loadBooks() -> Observable<[Book]> {
    return repository.getBooks()
        .map { realmBooks in
            realmBooks.map { $0.toModel() }
        }
}

// Reactor
func mutate(action: Action) -> Observable<Mutation> {
    case .loadBooks:
        return service.loadBooks()
            .map { .setBooks($0) }
}
```

**UI 바인딩**:
```swift
// ViewController
override func bind(reactor: MyReactor) {
    // State → UI (Driver 사용)
    reactor.state
        .map { $0.items }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: [])
        .drive(tableView.rx.items(cellIdentifier: "Cell")) { index, item, cell in
            cell.configure(with: item)
        }
        .disposed(by: disposeBag)

    // State → UI (Main Thread 보장)
    reactor.state
        .map { $0.isLoading }
        .asDriver(onErrorJustReturn: false)
        .drive(activityIndicator.rx.isAnimating)
        .disposed(by: disposeBag)
}
```

**에러 처리**:
```swift
service.loadData()
    .catch { error in
        // 에러를 Observable로 변환
        return .just(.setError(error))
    }
    .subscribe(onNext: { mutation in
        // 성공/실패 모두 처리
    })
    .disposed(by: disposeBag)
```

### 위반 예시

**Callback 사용**:
```swift
// ❌ Callback 패턴
func fetchBooks(completion: @escaping ([Book]) -> Void) {
    API.fetch { books in
        completion(books)
    }
}

// 사용
fetchBooks { books in
    self.books = books
    self.tableView.reloadData()
}
```

**수동 UI 업데이트**:
```swift
// ❌ 수동 업데이트
func loadData() {
    service.fetch { [weak self] data in
        self?.items = data
        self?.tableView.reloadData() // 수동
        self?.emptyView.isHidden = !data.isEmpty // 수동
        self?.loadingView.isHidden = true // 수동
    }
}
```

**DisposeBag 누락**:
```swift
// ❌ disposed(by:) 누락
reactor.state
    .map { $0.items }
    .subscribe(onNext: { items in
        // 메모리 누수
    })
```

### 위반 시 조치

**시나리오**: Callback 기반 API를 Observable로 변환

**Callback API**:
```swift
func fetchBooks(completion: @escaping (Result<[Book], Error>) -> Void)
```

**Observable 래퍼**:
```swift
func fetchBooks() -> Observable<[Book]> {
    return Observable.create { observer in
        self.fetchBooks { result in
            switch result {
            case .success(let books):
                observer.onNext(books)
                observer.onCompleted()
            case .failure(let error):
                observer.onError(error)
            }
        }
        return Disposables.create()
    }
}
```

## 고급 패턴

### 1. 여러 Observable 조합

**병렬 실행**:
```swift
Observable.zip(
    service.fetchBooks(),
    service.fetchQuotes(),
    service.fetchTags()
)
.map { books, quotes, tags in
    // 모두 완료 후 조합
}
```

**순차 실행**:
```swift
Observable.concat([
    .just(.setLoading(true)),
    service.fetch().map { .setData($0) },
    .just(.setLoading(false))
])
```

### 2. 조건부 실행

```swift
reactor.state
    .map { $0.isLoggedIn }
    .filter { $0 } // true일 때만
    .flatMap { _ in service.loadUserData() }
```

### 3. 재시도 패턴

```swift
service.fetch()
    .retry(3) // 3회 재시도
    .catch { error in
        .just(defaultValue)
    }
```

## 관련 원칙

- **[PRIN-001](unidirectional-data-flow.md)**: 단방향 데이터 흐름
- **[PRIN-003](immutable-state.md)**: 상태 불변성

## 계약

이 원칙을 구현하는 계약:
- **[CONT-001](../contracts/reactor-contract.md)**: Reactor 계약
- **[CONT-003](../contracts/service-contract.md)**: Service 계약
- **[CONT-004](../contracts/repository-contract.md)**: Repository 계약
- **[CONT-005](../contracts/view-contract.md)**: View 계약
