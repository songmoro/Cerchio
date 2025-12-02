---
Contract ID: CONT-001
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Principles: [PRIN-001, PRIN-002, PRIN-003, PRIN-004]
---

# Reactor 계약

## 계약 정의

Reactor는 **상태 관리만 담당**하며, 비즈니스 로직을 직접 구현하지 않는다.

```
Reactor = State Management Only
```

## 필수 책임 (Must)

### 1. Action-Mutation-State 흐름 구현

Reactor는 반드시 다음 흐름을 따라야 함:

```
User Event → Action → mutate() → Mutation → reduce() → New State
```

### 2. 상태 관리

- State를 불변(Immutable) Struct로 관리
- State 변경은 reduce()에서만 수행
- 모든 UI 관련 데이터를 State에 포함

### 3. 비동기 작업 조율

- mutate()에서 Service 호출
- Observable 체이닝으로 작업 순서 제어
- 에러 처리 및 Loading 상태 관리

### 4. Service 위임

- 복잡한 로직은 Service로 위임
- Repository를 직접 호출하지 않음
- mutate()는 Service 호출 + 매핑만 수행

## 금지사항 (Must Not)

### 1. UI 로직 포함 금지

```
❌ import UIKit
❌ import SwiftUI
❌ UIViewController, UIView 타입 참조
```

### 2. 직접 데이터 접근 금지

```
❌ import RealmSwift
❌ Repository 직접 호출 (Service를 통해야 함)
❌ Database 직접 접근
```

### 3. 네비게이션 수행 금지

```
❌ NavigationController 참조
❌ ViewController 생성
❌ 화면 전환 수행
```

대신 NavigationEvent를 발행:
```swift
let navigationEvents = PublishRelay<NavigationEvent>()

func mutate(action: Action) -> Observable<Mutation> {
    navigationEvents.accept(.showDetail)
    return .empty()
}
```

### 4. 복잡한 비즈니스 로직 금지

mutate() 메서드는 10줄 이하로 유지:
```swift
// ✅ 준수 (3줄)
func mutate(action: Action) -> Observable<Mutation> {
    case .save:
        return service.saveData()
            .map { .dataSaved }
}

// ❌ 위반 (30줄)
func mutate(action: Action) -> Observable<Mutation> {
    case .save:
        // 복잡한 검증 로직
        // 데이터 가공
        // 여러 Repository 호출
        // ... 30줄
}
```

## 구현 체크리스트

### 기본 구조

- [ ] `Reactor` 프로토콜을 채택했는가?
- [ ] `Action`, `Mutation`, `State` enum/struct를 정의했는가?
- [ ] `initialState`를 정의했는가?
- [ ] `mutate(action:)` 메서드를 구현했는가?
- [ ] `reduce(state:mutation:)` 메서드를 구현했는가?

### State 관리

- [ ] State가 struct인가?
- [ ] State에 UI 관련 모든 데이터가 포함되어 있는가?
- [ ] State에 Realm 객체가 없는가? (DTO 사용)
- [ ] State에 class 타입이 없는가?

### mutate() 검증

- [ ] mutate()가 10줄 이하인가?
- [ ] 복잡한 로직은 Service로 위임했는가?
- [ ] Observable을 반환하는가?
- [ ] 에러 처리를 포함하는가?

### reduce() 검증

- [ ] reduce()가 순수 함수인가? (부작용 없음)
- [ ] 새로운 State를 반환하는가?
- [ ] State를 직접 변경하지 않는가? (복사 후 변경)

### 의존성 검증

- [ ] `import UIKit`이 없는가?
- [ ] `import RealmSwift`가 없는가?
- [ ] Repository를 직접 import하지 않는가?
- [ ] Service를 생성자로 주입받는가?

### 파일 크기

- [ ] 파일 길이가 200줄 이하인가?
- [ ] Action이 10개 이하인가?
- [ ] Mutation이 15개 이하인가?

## 코드 검증

### 자동 검증 스크립트

```bash
# 1. UIKit import 검증
grep "import UIKit" Features/*/Reactor/*Reactor.swift
# 결과 없어야 함

# 2. RealmSwift import 검증
grep "import RealmSwift" Features/*/Reactor/*Reactor.swift
# 결과 없어야 함

# 3. 파일 길이 검증
find Features -name "*Reactor.swift" -exec wc -l {} \; | awk '$1 > 200 {print "Too long: " $2}'

# 4. State가 struct인지 검증
grep "struct State" Features/*/Reactor/*Reactor.swift
# 모든 Reactor에 존재해야 함
```

### 수동 검증 (Code Review)

Pull Request 체크리스트:

**기본 구조**:
- [ ] Reactor 파일 이름이 `{Feature}Reactor.swift` 형식인가?
- [ ] Action, Mutation, State가 명확히 정의되어 있는가?

**원칙 준수**:
- [ ] [PRIN-001 단방향 데이터 흐름](../principles/unidirectional-data-flow.md) 준수
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md) 준수
- [ ] [PRIN-003 상태 불변성](../principles/immutable-state.md) 준수
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md) 준수

**코드 품질**:
- [ ] mutate() 메서드가 단순한가? (복잡한 로직은 Service에)
- [ ] reduce()에 부작용이 없는가?
- [ ] 네비게이션을 직접 수행하지 않는가?

## 준수 예시

```swift
import ReactorKit
import RxSwift

final class BookDetailReactor: Reactor {
    // MARK: - Action
    enum Action {
        case loadDetail
        case saveQuote(String)
        case deletePhoto(String)
    }

    // MARK: - Mutation
    enum Mutation {
        case setBookDetail(BookDetail)
        case setLoading(Bool)
        case setError(Error?)
        case quoteSaved
    }

    // MARK: - State
    struct State {
        var bookDetail: BookDetail?
        var isLoading: Bool = false
        var error: Error?
    }

    // MARK: - Properties
    let initialState: State
    private let service: BookDetailServiceProtocol
    let navigationEvents = PublishRelay<NavigationEvent>()

    // MARK: - Initialization
    init(service: BookDetailServiceProtocol) {
        self.service = service
        self.initialState = State()
    }

    // MARK: - Mutate (간결함)
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadDetail:
            return loadDetailMutation()

        case .saveQuote(let text):
            return service.saveQuote(text: text)
                .map { _ in .quoteSaved }
                .catch { .just(.setError($0)) }

        case .deletePhoto(let id):
            return service.deletePhoto(id: id)
                .map { _ in .quoteSaved }
        }
    }

    // MARK: - Reduce (순수 함수)
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        newState.error = nil

        switch mutation {
        case .setBookDetail(let detail):
            newState.bookDetail = detail

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error

        case .quoteSaved:
            // Service에서 처리, 여기선 State만 변경
            break
        }

        return newState
    }

    // MARK: - Private
    private func loadDetailMutation() -> Observable<Mutation> {
        return .concat([
            .just(.setLoading(true)),
            service.loadBookDetail()
                .map { .setBookDetail($0) }
                .catch { .just(.setError($0)) },
            .just(.setLoading(false))
        ])
    }

    enum NavigationEvent {
        case showQuoteSave
        case showPhotoViewer(String)
    }
}
```

## 위반 예시

```swift
import ReactorKit
import RxSwift
import UIKit // ❌ UI import
import RealmSwift // ❌ Database import

final class BookDetailReactor: Reactor {
    // ❌ Repository 직접 참조
    private let bookRepository: BookRepository
    private let quoteRepository: QuoteRepository

    func mutate(action: Action) -> Observable<Mutation> {
        case .saveQuote(let text):
            // ❌ 복잡한 비즈니스 로직 (Service로 분리해야 함)
            guard !text.isEmpty else {
                return .just(.setError(ValidationError.emptyText))
            }

            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 10 else {
                return .just(.setError(ValidationError.tooShort))
            }

            // ❌ 직접 Repository 호출
            let realm = try! Realm()
            let quote = RealmQuote()
            quote.text = trimmed
            quote.createdAt = Date()

            try! realm.write {
                realm.add(quote)
            }

            // ❌ 네비게이션 직접 수행
            let successVC = SuccessViewController()
            navigationController?.present(successVC, animated: true)

            return .just(.quoteSaved)
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .quoteSaved:
            // ❌ 부작용 (순수 함수 위반)
            print("Quote saved!")
            UserDefaults.standard.set(true, forKey: "hasQuote")
        }

        return newState
    }
}
```

## 위반 시 수정 방법

### 문제: Repository 직접 호출

**Before (위반)**:
```swift
class BookDetailReactor {
    let repository: BookRepository

    func mutate(action: Action) -> Observable<Mutation> {
        return repository.getBook(id: id)
            .map { .setBook($0) }
    }
}
```

**After (계약 준수)**:
```swift
// 1. Service 생성
class BookDetailService {
    let repository: BookRepositoryProtocol

    func loadBook(id: String) -> Observable<Book> {
        return repository.getBook(id: id)
    }
}

// 2. Reactor는 Service 호출
class BookDetailReactor {
    let service: BookDetailServiceProtocol

    func mutate(action: Action) -> Observable<Mutation> {
        return service.loadBook(id: id)
            .map { .setBook($0) }
    }
}
```

### 문제: 복잡한 mutate()

**Before (위반)**:
```swift
func mutate(action: Action) -> Observable<Mutation> {
    case .save:
        // 30줄의 복잡한 로직
        // 검증, 변환, Repository 조합 등
}
```

**After (계약 준수)**:
```swift
// 1. 로직을 Service로 이동
class MyService {
    func saveData(...) -> Observable<Void> {
        // 복잡한 로직을 여기로
    }
}

// 2. Reactor는 단순하게
func mutate(action: Action) -> Observable<Mutation> {
    case .save:
        return service.saveData(...)
            .map { .dataSaved }
}
```

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-003](../principles/immutable-state.md) - 상태 불변성
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-003](service-contract.md) - Service 계약
- [CONT-005](view-contract.md) - View 계약

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md) - Feature 구현 가이드
