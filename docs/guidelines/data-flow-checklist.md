---
Guide ID: GUIDE-002
Version: 1.0.0
Last Updated: 2025-12-02
Related Principles: [PRIN-001, PRIN-004]
---

# 데이터 흐름 체크리스트

데이터 흐름 문제를 디버깅하고 검증하기 위한 체크리스트입니다.

## 정상적인 데이터 흐름

```
View → Action → Reactor.mutate() → Service → Repository → Database
                       ↓
                  Mutation → Reactor.reduce() → State → View
```

## 1. View 계층 검증

### Input (View → Reactor)

- [ ] 사용자 이벤트가 Action으로 변환되는가?
- [ ] `bind(to: reactor.action)` 사용하는가?
- [ ] `.disposed(by: disposeBag)` 호출하는가?

**디버깅 방법**:
```swift
// Action이 발행되는지 확인
reactor.action
    .do(onNext: { print("🔵 Action: \($0)") })
    .subscribe()
    .disposed(by: disposeBag)
```

### Output (State → View)

- [ ] State 변경에 반응하는가?
- [ ] Driver를 사용하는가?
- [ ] `.distinctUntilChanged()` 사용하는가?
- [ ] Main Thread에서 UI 업데이트하는가?

**디버깅 방법**:
```swift
// State 변경 확인
reactor.state
    .do(onNext: { print("🟢 State: \($0)") })
    .asDriver(onErrorJustReturn: initialState)
    .drive()
    .disposed(by: disposeBag)
```

### 일반적인 문제

**문제**: UI가 업데이트되지 않음

```swift
// ❌ 문제 코드
reactor.state
    .map { $0.items }
    .subscribe(onNext: { items in
        self.items = items
    })
    .disposed(by: disposeBag)
```

**해결**:
```swift
// ✅ 해결 코드
reactor.state
    .map { $0.items }
    .distinctUntilChanged() // 중복 업데이트 방지
    .asDriver(onErrorJustReturn: []) // Main thread 보장
    .drive(onNext: { [weak self] items in
        self?.items = items
    })
    .disposed(by: disposeBag)
```

## 2. Reactor 계층 검증

### Action → Mutation

- [ ] mutate() 메서드가 호출되는가?
- [ ] Observable<Mutation>을 반환하는가?
- [ ] 에러를 catch하는가?
- [ ] Service 호출이 성공하는가?

**디버깅 방법**:
```swift
func mutate(action: Action) -> Observable<Mutation> {
    print("🔵 mutate called: \(action)")

    switch action {
    case .load:
        return service.loadData()
            .do(onNext: { print("🟢 Service success: \($0)") })
            .do(onError: { print("🔴 Service error: \($0)") })
            .map { .setData($0) }
            .catch { .just(.setError($0)) }
    }
}
```

### Mutation → State

- [ ] reduce() 메서드가 호출되는가?
- [ ] 새로운 State를 반환하는가?
- [ ] State가 실제로 변경되는가?

**디버깅 방법**:
```swift
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    print("🔵 reduce called: \(mutation)")

    switch mutation {
    case .setData(let data):
        newState.data = data
        print("🟢 New state: \(newState)")
    }

    return newState
}
```

### 일반적인 문제

**문제**: Mutation이 발행되지 않음

```swift
// ❌ 문제 코드
func mutate(action: Action) -> Observable<Mutation> {
    service.saveData() // Observable 반환 안 함
    return .empty()
}
```

**해결**:
```swift
// ✅ 해결 코드
func mutate(action: Action) -> Observable<Mutation> {
    return service.saveData()
        .map { .dataSaved }
}
```

**문제**: State가 변경되지 않음

```swift
// ❌ 문제 코드
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setData(let data):
        state.data = data // 원본 변경 (복사본 아님)
    }
    return state // 변경 안 된 원본 반환
}
```

**해결**:
```swift
// ✅ 해결 코드
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setData(let data):
        newState.data = data // 복사본 변경
    }
    return newState // 변경된 복사본 반환
}
```

## 3. Service 계층 검증

### Observable 체이닝

- [ ] Observable이 올바르게 반환되는가?
- [ ] flatMap, zip, concat이 올바르게 사용되는가?
- [ ] 에러가 전파되는가?

**디버깅 방법**:
```swift
func loadBookDetail(bookId: String) -> Observable<BookDetail> {
    return Observable.zip(
        bookRepository.getBook(id: bookId)
            .do(onNext: { print("🟢 Book loaded: \($0)") }),
        quoteRepository.getQuotes(for: bookId)
            .do(onNext: { print("🟢 Quotes loaded: \($0)") })
    )
    .do(onNext: { print("🟢 Zip completed") })
    .map { book, quotes in
        BookDetail(book: book.toDTO(), quotes: quotes.map { $0.toDTO() })
    }
    .do(onNext: { print("🟢 DTO conversion completed") })
}
```

### DTO 변환

- [ ] Realm 객체를 DTO로 변환하는가?
- [ ] 변환 메서드가 올바른가?

**디버깅 방법**:
```swift
func toDTO() -> Book {
    print("🔵 Converting Realm to DTO: \(self)")
    let dto = Book(id: id, title: title)
    print("🟢 DTO created: \(dto)")
    return dto
}
```

### 일반적인 문제

**문제**: Observable이 완료되지 않음

```swift
// ❌ 문제 코드
func loadData() -> Observable<Data> {
    return Observable.create { observer in
        // onCompleted() 호출 안 함
        observer.onNext(data)
        return Disposables.create()
    }
}
```

**해결**:
```swift
// ✅ 해결 코드
func loadData() -> Observable<Data> {
    return Observable.create { observer in
        observer.onNext(data)
        observer.onCompleted() // 필수!
        return Disposables.create()
    }
}
```

## 4. Repository 계층 검증

### Realm 작업

- [ ] Realm 트랜잭션이 성공하는가?
- [ ] 쿼리가 올바른가?
- [ ] Thread-safe하게 작업하는가?

**디버깅 방법**:
```swift
func save(_ book: RealmBook) -> Observable<RealmBook> {
    return Observable.create { observer in
        do {
            let realm = try Realm()
            print("🟢 Realm opened")

            try realm.write {
                realm.add(book)
                print("🟢 Book added: \(book)")
            }

            observer.onNext(book)
            observer.onCompleted()
        } catch {
            print("🔴 Realm error: \(error)")
            observer.onError(error)
        }

        return Disposables.create()
    }
}
```

### 일반적인 문제

**문제**: Realm Thread 에러

```swift
// ❌ 문제 코드 (다른 Thread에서 접근)
Task {
    let books = realm.objects(RealmBook.self) // ❌ Thread-confined
    let titles = books.map { $0.title }
}
```

**해결**:
```swift
// ✅ 해결 코드 (Main Thread에서 데이터 추출)
let realm = try Realm()
let books = realm.objects(RealmBook.self)
let titles = books.map { $0.title } // Main Thread에서 추출

Task {
    await processData(titles) // 추출된 데이터 사용
}
```

## 5. 전체 흐름 검증

### 단계별 체크리스트

**1단계: View Input**
- [ ] 버튼 탭 → Action 발행 확인
- [ ] TextField 입력 → Action 발행 확인

**2단계: Reactor mutate()**
- [ ] Action 수신 확인
- [ ] Service 호출 확인
- [ ] Mutation 발행 확인

**3단계: Service**
- [ ] Repository 호출 확인
- [ ] DTO 변환 확인
- [ ] Observable 반환 확인

**4단계: Repository**
- [ ] Realm 작업 성공 확인
- [ ] 데이터 반환 확인

**5단계: Reactor reduce()**
- [ ] Mutation 수신 확인
- [ ] State 변경 확인
- [ ] 새 State 반환 확인

**6단계: View Output**
- [ ] State 변경 감지 확인
- [ ] UI 업데이트 확인

### 전체 디버깅 로그

```swift
// View
button.rx.tap
    .do(onNext: { print("1️⃣ Button tapped") })
    .map { Reactor.Action.load }
    .do(onNext: { print("2️⃣ Action created: \($0)") })
    .bind(to: reactor.action)
    .disposed(by: disposeBag)

// Reactor
func mutate(action: Action) -> Observable<Mutation> {
    print("3️⃣ mutate called: \(action)")
    return service.loadData()
        .do(onNext: { print("4️⃣ Service completed") })
        .map { .setData($0) }
        .do(onNext: { print("5️⃣ Mutation created: \($0)") })
}

func reduce(state: State, mutation: Mutation) -> State {
    print("6️⃣ reduce called: \(mutation)")
    var newState = state
    newState.data = extractData(from: mutation)
    print("7️⃣ New state: \(newState)")
    return newState
}

// View
reactor.state
    .do(onNext: { print("8️⃣ State changed: \($0)") })
    .map { $0.data }
    .asDriver(onErrorJustReturn: [])
    .drive(onNext: { print("9️⃣ UI updated") })
    .disposed(by: disposeBag)
```

## 디버깅 도구

### 1. RxSwift Debug Operator

```swift
reactor.state
    .debug("State") // 모든 이벤트 출력
    .map { $0.items }
    .asDriver(onErrorJustReturn: [])
    .drive()
    .disposed(by: disposeBag)
```

### 2. Breakpoints

- `mutate(action:)` 시작점
- `reduce(state:mutation:)` 시작점
- Service 메서드 시작점
- Repository 메서드 시작점

### 3. Instruments

- Time Profiler: 성능 병목 지점
- Allocations: 메모리 누수
- Leaks: Retain Cycle

## 일반적인 문제 해결

### 문제 1: UI가 업데이트되지 않음

**체크리스트**:
1. [ ] State가 변경되었는가?
2. [ ] `.distinctUntilChanged()` 사용 중인가?
3. [ ] Equatable 구현이 올바른가?
4. [ ] Main Thread에서 업데이트하는가?

### 문제 2: 데이터가 로드되지 않음

**체크리스트**:
1. [ ] Repository가 데이터를 반환하는가?
2. [ ] Service가 Observable을 반환하는가?
3. [ ] Reactor가 Mutation을 발행하는가?
4. [ ] reduce()가 State를 변경하는가?

### 문제 3: 에러가 무시됨

**체크리스트**:
1. [ ] `.catch` 연산자를 사용하는가?
2. [ ] Error Mutation을 정의했는가?
3. [ ] State에 error 필드가 있는가?
4. [ ] View가 error를 구독하는가?

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**가이드**:
- [GUIDE-001](feature-implementation.md) - Feature 구현 가이드
- [GUIDE-003](state-management-guide.md) - State 관리 가이드
