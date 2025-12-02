---
Principle ID: PRIN-003
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Documents: [PRIN-001, PRIN-004]
---

# 상태 불변성 원칙

## 원칙 정의

상태(State)는 불변(Immutable)이며, 변경 시 새로운 상태를 생성한다.

```
Old State + Mutation = New State (복사본)
```

## 문제 배경 (Why)

### 가변 상태위반 시 발생하는 문제

**1. 예측 불가능한 변경**
```swift
// 가변 상태
class State {
    var items: [Item] = []
}

// 어디서든 변경 가능
state.items.append(newItem) // A에서 변경
state.items.remove(at: 0)   // B에서 변경
// → 누가 언제 변경했는지 추적 불가
```

**2. 동시성 문제 (Race Condition)**
```swift
// Thread 1
state.items.append(item1)

// Thread 2 (동시 실행)
state.items.append(item2)

// → 데이터 손실 또는 크래시 가능
```

**3. 시간 여행 디버깅 불가능**
```
State History: ❌
- 이전 상태로 되돌리기 불가능
- 상태 변화 추적 불가능
- 디버깅 어려움
```

**4. 테스트 어려움**
```swift
// 테스트 간 상태 공유
test1() { state.items = [item1] }
test2() { state.items // item1이 남아있음 }
// → 테스트 독립성 깨짐
```

### 불변 상태특성

**1. 예측 가능성**
```swift
let oldState = State(items: [item1])
let newState = oldState.adding(item2)

// oldState는 변경되지 않음
// newState는 새로운 객체
```

**2. 스레드 안전성**
```swift
// 여러 스레드에서 동시 읽기 가능
Thread 1: read state.items
Thread 2: read state.items
// → 안전 (불변이므로)
```

**3. 시간 여행 디버깅**
```
State History: ✅
State 1 → State 2 → State 3 → State 4
           ↑ 여기로 되돌리기 가능
```

**4. 테스트 용이성**
```swift
let initialState = State(items: [])
let afterAdd = initialState.adding(item1)
let afterRemove = afterAdd.removing(item1)

// 각 상태가 독립적
// 테스트 간 간섭 없음
```

## 제약조건 (Constraints)

### 1. State는 Struct

**필수**:
```swift
// State는 반드시 struct (값 타입)
struct State {
    var items: [Item]
    var isLoading: Bool
}
```

**금지**:
```swift
// State를 class로 선언 금지
class State { // ❌
    var items: [Item]
}
```

### 2. 변경 시 복사

**필수**:
```swift
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state // 복사
    newState.items = updatedItems
    return newState // 새 State 반환
}
```

**금지**:
```swift
func reduce(state: State, mutation: Mutation) -> State {
    state.items = updatedItems // ❌ struct라 컴파일 에러
    return state
}
```

### 3. State 내부도 불변

**권장**:
```swift
struct State {
    let items: [Item] // let 사용
    let isLoading: Bool
}

// 변경 시 새 State 생성
let newState = State(
    items: updatedItems,
    isLoading: false
}
```

**허용 (실용적 선택)**:
```swift
struct State {
    var items: [Item] // var 허용
    var isLoading: Bool
}

// reduce()에서만 변경 가능
var newState = state
newState.items = updatedItems
```

### 4. Nested Object도 불변

준수 예시:
```swift
struct State {
    var bookDetail: BookDetail? // Struct
}

struct BookDetail {
    let title: String
    let quotes: [Quote] // Struct 배열
}
```

위반 예시:
```swift
struct State {
    var book: RealmBook? // ❌ RealmBook은 class
}

// Realm 객체는 가변이므로 DTO로 변환
struct BookDetail {
    let title: String
    // RealmBook → BookDetail 변환 필요
}
```

## 코드 검증

### 자동 검증 (CI 가능)

**1. State가 Struct인지 검증**
```bash
# Reactor 파일에서 State 정의 찾기
grep -A 5 "struct State" Features/*/Reactor/*Reactor.swift

# class State가 있으면 에러
grep "class State" Features/*/Reactor/*Reactor.swift
```

**2. Realm 객체가 State에 없는지 검증**
```bash
# State 안에 Realm 타입이 있으면 에러
grep -A 20 "struct State" *Reactor.swift | grep "Realm"
```

### 수동 검증 (Code Review)

**Reactor State 체크리스트**:
- [ ] State가 struct인가?
- [ ] State 프로퍼티에 Realm 객체가 없는가?
- [ ] State 프로퍼티에 class 타입이 없는가?
- [ ] reduce()가 새 State를 반환하는가?

**DTO 변환 체크리스트**:
- [ ] Realm 객체를 DTO로 변환했는가?
- [ ] DTO가 struct 또는 불변 class인가?
- [ ] DTO에 비즈니스 로직이 없는가?

### 준수 예시

**State 정의**:
```swift
struct State {
    // 불변 타입 사용
    var bookDetail: BookDetail?
    var quotes: [Quote]
    var isLoading: Bool
    var error: Error?
}

// DTO (Struct)
struct BookDetail {
    let id: String
    let title: String
    let author: String
    let coverImagePath: String?
}
```

**reduce() 구현**:
```swift
func reduce(state: State, mutation: Mutation) -> State {
    var newState = state // 복사

    switch mutation {
    case .setBookDetail(let bookDetail):
        newState.bookDetail = bookDetail

    case .appendQuotes(let newQuotes):
        newState.quotes.append(contentsOf: newQuotes)
    }

    return newState // 새 State 반환
}
```

**Realm → DTO 변환**:
```swift
// Service에서 변환
func loadBookDetail(bookId: String) -> Observable<BookDetail> {
    return Observable.create { observer in
        let realm = try Realm()
        let realmBook = realm.objects(RealmBook.self)
            .filter("id == %@", bookId)
            .first

        // Realm 객체 → DTO 변환
        if let book = realmBook {
            let dto = BookDetail(
                id: book.id,
                title: book.title,
                author: book.author,
                coverImagePath: book.coverImagePath
            )
            observer.onNext(dto)
        }

        observer.onCompleted()
        return Disposables.create()
    }
}
```

### 위반 예시

**가변 State**:
```swift
// ❌ class 사용
class State {
    var items: [Item] = []
}

func reduce(state: State, mutation: Mutation) -> State {
    // 같은 객체를 변경
    state.items.append(newItem)
    return state // 새 객체가 아님
}
```

**Realm 객체를 State에 직접 저장**:
```swift
// ❌ Realm 객체는 가변
struct State {
    var book: RealmBook? // Thread-confined, 가변
}

// 문제:
// - Realm 객체는 다른 스레드에서 접근 불가
// - Realm 객체는 가변이므로 언제든 변경 가능
// - 불변성 원칙 위반
```

**불필요한 가변성**:
```swift
// ❌ Equatable 구현을 위해 class 사용
class State: Equatable {
    var items: [Item]

    static func == (lhs: State, rhs: State) -> Bool {
        lhs.items == rhs.items
    }
}

// 해결: Struct는 자동 Equatable
struct State: Equatable {
    var items: [Item]
    // 자동으로 Equatable 구현됨
}
```

### 위반 시 조치

**시나리오**: Realm 객체를 State에 저장하고 싶음

**잘못된 해결책**:
```swift
struct State {
    var book: RealmBook? // Realm 객체 직접 저장
}
```

**올바른 해결책**:
```swift
// 1. DTO 정의
struct BookDetail {
    let id: String
    let title: String
    let author: String
}

// 2. State에 DTO 저장
struct State {
    var bookDetail: BookDetail?
}

// 3. Service에서 Realm → DTO 변환
func loadBookDetail() -> Observable<BookDetail> {
    return realmBook.map { book in
        BookDetail(
            id: book.id,
            title: book.title,
            author: book.author
        )
    }
}
```

## Derived State (계산 프로퍼티)

### 사용 시기

**저장 vs 계산**:
```swift
struct State {
    var items: [Item]

    // ✅ 계산 프로퍼티 (저장하지 않음)
    var itemCount: Int {
        items.count
    }

    // ✅ 계산 프로퍼티
    var hasItems: Bool {
        !items.isEmpty
    }
}
```

**이점**:
- State 크기 감소
- 중복 데이터 없음
- 항상 최신 값

**주의**:
```swift
// ❌ 계산이 복잡하면 저장
var expensiveCalculation: Int {
    items.map { $0.complexity }.reduce(0, +) // 비용 높음
}

// ✅ 저장
var totalComplexity: Int
```

## 관련 원칙

- **[PRIN-001](unidirectional-data-flow.md)**: 단방향 데이터 흐름
- **[PRIN-004](reactive-programming.md)**: 반응형 프로그래밍

## 계약

이 원칙을 구현하는 계약:
- **[CONT-001](../contracts/reactor-contract.md)**: Reactor 계약
