---
Principle ID: PRIN-005
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Documents: [PRIN-001, PRIN-002]
---

# 의존성 역전 원칙

## 원칙 정의

상위 계층은 구현체가 아닌 추상화(Protocol)에 의존하며, 의존성은 외부에서 주입된다.

```
High-Level → Protocol ← Low-Level
(구현체에 의존하지 않음)
```

## 문제 배경 (Why)

### 구현체 직접 의존의 문제

**1. 테스트 불가능**
```swift
// Reactor가 구현체 직접 생성
class MyReactor {
    let repository = BookRepository() // 구체 타입

    func loadData() {
        repository.fetch() // 실제 Database 접근
    }
}

// 테스트 시:
// - 실제 Database 필요
// - Mock 주입 불가능
// - 테스트 속도 느림
```

**2. 구현 교체 불가능**
```swift
class MyReactor {
    let repository = BookRepository()
}

// Realm → CoreData 변경 시:
// - 모든 Reactor 수정 필요
// - 변경 영향 범위 확대
```

**3. 순환 의존성 발생 가능**
```swift
class A {
    let b = B()
}

class B {
    let a = A() // 순환 의존
}

// 컴파일 불가능
```

**4. 의존성 파악 어려움**
```swift
class MyReactor {
    init() {
        // 내부에서 생성 → 외부에서 알 수 없음
        self.repository = BookRepository()
        self.service = BookService()
    }
}
```

### 의존성 역전특성

**1. 테스트 용이성**
```swift
// Protocol 의존
class MyReactor {
    let repository: BookRepositoryProtocol

    init(repository: BookRepositoryProtocol) {
        self.repository = repository
    }
}

// 테스트 시 Mock 주입
let mock = MockBookRepository()
let reactor = MyReactor(repository: mock)
```

**2. 구현 교체 가능**
```swift
// Production
let repository: BookRepositoryProtocol = RealmBookRepository()

// Development
let repository: BookRepositoryProtocol = InMemoryBookRepository()

// Testing
let repository: BookRepositoryProtocol = MockBookRepository()
```

**3. 순환 의존성 방지**
```swift
protocol BProtocol {}

class A {
    let b: BProtocol
    init(b: BProtocol) { self.b = b }
}

class B: BProtocol {
    // A를 알 필요 없음
}
```

**4. 명시적 의존성**
```swift
class MyReactor {
    init(
        repository: BookRepositoryProtocol,
        service: BookServiceProtocol
    ) {
        // 외부에서 의존성 명확히 알 수 있음
    }
}
```

## 제약조건 (Constraints)

### 1. Protocol 기반 의존성

**필수**:
```swift
// Protocol 정의
protocol BookRepositoryProtocol {
    func fetch() -> Observable<[Book]>
    func save(_ book: Book) -> Observable<Void>
}

// 상위 계층은 Protocol에 의존
class BookService {
    private let repository: BookRepositoryProtocol

    init(repository: BookRepositoryProtocol) {
        self.repository = repository
    }
}
```

**금지**:
```swift
// ❌ 구체 타입 의존
class BookService {
    private let repository: BookRepository // 구체 타입
}
```

### 2. 생성자 주입 (Constructor Injection)

**필수**:
```swift
class MyReactor {
    private let service: MyServiceProtocol

    init(service: MyServiceProtocol) {
        self.service = service
    }
}
```

**금지**:
```swift
// ❌ 내부 생성
class MyReactor {
    private let service = MyService()
}

// ❌ Setter 주입
class MyReactor {
    var service: MyServiceProtocol?

    func setService(_ service: MyServiceProtocol) {
        self.service = service
    }
}
```

### 3. ServiceFactory 패턴

**권장**:
```swift
// ServiceFactory가 의존성 생성 담당
class ServiceFactory {
    func createBookRepository() -> BookRepositoryProtocol {
        return BookRepository()
    }

    func createBookService() -> BookServiceProtocol {
        let repository = createBookRepository()
        return BookService(repository: repository)
    }
}

// 사용
class MyReactor {
    private let service: BookServiceProtocol

    init(serviceFactory: ServiceFactory) {
        self.service = serviceFactory.createBookService()
    }
}
```

### 4. Protocol 설계 원칙

**ISP (Interface Segregation Principle)**:
```swift
// ✅ 역할별로 Protocol 분리
protocol Readable {
    func fetch() -> Observable<[Item]>
}

protocol Writable {
    func save(_ item: Item) -> Observable<Void>
}

// 필요한 것만 의존
class ReadOnlyService {
    let repository: Readable // Writable 불필요
}
```

**금지**:
```swift
// ❌ 거대한 Protocol
protocol Repository {
    func fetch() -> Observable<[Item]>
    func save(_ item: Item) -> Observable<Void>
    func delete(_ item: Item) -> Observable<Void>
    func search(_ query: String) -> Observable<[Item]>
    func update(_ item: Item) -> Observable<Void>
    // 사용하지 않는 메서드도 구현 강제
}
```

## 코드 검증

### 자동 검증 (CI 가능)

**1. Protocol 사용 검증**
```bash
# Repository 타입 선언 검사
grep "let repository:" Features/ -r

# Protocol이 아닌 구체 타입 검출
grep "let repository: [A-Z][a-zA-Z]*Repository" Features/ -r
# 결과가 있으면 위반
```

**2. 내부 생성 검출**
```bash
# init 내부에서 생성하는 경우 검출
grep -A 5 "init(" Features/ -r | grep "= [A-Z]"
```

### 수동 검증 (Code Review)

**의존성 주입 체크리스트**:
- [ ] 모든 의존성이 생성자로 주입되는가?
- [ ] Protocol 타입으로 선언되어 있는가?
- [ ] 내부에서 `new` 또는 `= SomeType()`이 없는가?
- [ ] ServiceFactory를 통해 생성되는가?

**Protocol 설계 체크리스트**:
- [ ] Protocol이 단일 책임을 가지는가?
- [ ] Protocol 메서드가 5개 이하인가?
- [ ] 사용하지 않는 메서드를 강제하지 않는가?

### 준수 예시

**Protocol 정의**:
```swift
// Repository Protocol
protocol BookRepositoryProtocol {
    func getAll() -> Observable<[RealmBook]>
    func get(by id: String) -> Observable<RealmBook?>
    func save(_ book: RealmBook) -> Observable<RealmBook>
    func delete(_ book: RealmBook) -> Observable<Void>
}

// Service Protocol
protocol BookServiceProtocol {
    func loadBooks() -> Observable<[Book]>
    func saveBook(title: String, author: String) -> Observable<Void>
}
```

**생성자 주입**:
```swift
// Reactor
class BookDetailReactor: Reactor {
    private let service: BookDetailServiceProtocol

    init(service: BookDetailServiceProtocol) {
        self.service = service
        self.initialState = State()
    }
}

// Service
class BookDetailService: BookDetailServiceProtocol {
    private let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    func loadPhotos() -> Observable<[Photo]> {
        let repository = serviceFactory.createPhotoRepository()
        return repository.getAll()
    }
}
```

**ServiceFactory 사용**:
```swift
// Coordinator에서 주입
class BookDetailCoordinator {
    func start(with dependencies: Dependencies) {
        let service = BookDetailService(
            serviceFactory: dependencies.serviceFactory
        )

        let reactor = BookDetailReactor(service: service)

        let viewController = BookDetailViewController()
        viewController.reactor = reactor
    }
}
```

**테스트**:
```swift
// Mock Protocol 구현
class MockBookRepository: BookRepositoryProtocol {
    var getAllResult: Observable<[RealmBook]> = .just([])

    func getAll() -> Observable<[RealmBook]> {
        return getAllResult
    }
}

// 테스트에서 Mock 주입
func testLoadBooks() {
    let mockRepository = MockBookRepository()
    mockRepository.getAllResult = .just([mockBook1, mockBook2])

    let service = BookService(repository: mockRepository)
    let reactor = BookReactor(service: service)

    // 테스트 수행
}
```

### 위반 예시

**구체 타입 의존**:
```swift
// ❌ 구체 타입
class BookService {
    private let repository: BookRepository // Protocol이 아님

    init(repository: BookRepository) {
        self.repository = repository
    }
}

// 문제:
// - Mock 주입 불가능
// - 구현 교체 불가능
```

**내부 생성**:
```swift
// ❌ 내부에서 생성
class BookReactor {
    private let service: BookService

    init() {
        self.service = BookService() // 내부 생성
    }
}

// 문제:
// - 테스트 시 Mock 주입 불가능
// - 의존성이 숨겨짐
```

**거대한 Protocol**:
```swift
// ❌ 모든 기능을 하나의 Protocol에
protocol BookRepository {
    func getAll() -> Observable<[Book]>
    func getById(_ id: String) -> Observable<Book?>
    func save(_ book: Book) -> Observable<Void>
    func delete(_ book: Book) -> Observable<Void>
    func search(_ query: String) -> Observable<[Book]>
    func getRecent(limit: Int) -> Observable<[Book]>
    func getByAuthor(_ author: String) -> Observable<[Book]>
    // 10개 이상의 메서드...
}

// 문제:
// - 사용하지 않는 메서드도 구현 필요
// - Protocol이 너무 커짐
```

### 위반 시 조치

**시나리오**: Reactor가 Repository를 직접 생성

**잘못된 코드**:
```swift
class BookReactor {
    let repository = BookRepository()

    func loadBooks() {
        repository.getAll()
    }
}
```

**수정 단계**:

**1. Protocol 정의**:
```swift
protocol BookRepositoryProtocol {
    func getAll() -> Observable<[Book]>
}
```

**2. Repository가 Protocol 구현**:
```swift
class BookRepository: BookRepositoryProtocol {
    func getAll() -> Observable<[Book]> {
        // 구현
    }
}
```

**3. Service 추가 (Reactor와 Repository 분리)**:
```swift
protocol BookServiceProtocol {
    func loadBooks() -> Observable<[Book]>
}

class BookService: BookServiceProtocol {
    private let repository: BookRepositoryProtocol

    init(repository: BookRepositoryProtocol) {
        self.repository = repository
    }

    func loadBooks() -> Observable<[Book]> {
        return repository.getAll()
    }
}
```

**4. Reactor 수정 (Service 주입)**:
```swift
class BookReactor {
    private let service: BookServiceProtocol

    init(service: BookServiceProtocol) {
        self.service = service
    }

    func mutate(action: Action) -> Observable<Mutation> {
        case .loadBooks:
            return service.loadBooks()
                .map { .setBooks($0) }
    }
}
```

**5. Coordinator에서 주입**:
```swift
class BookCoordinator {
    func start() {
        let repository: BookRepositoryProtocol = BookRepository()
        let service: BookServiceProtocol = BookService(repository: repository)
        let reactor = BookReactor(service: service)

        viewController.reactor = reactor
    }
}
```

## ServiceFactory 패턴

### 목적

- 의존성 생성 로직 중앙화
- 환경별 구현 교체 (Dev/Prod/Test)
- 의존성 캐싱

### 구현

```swift
class ServiceFactory {
    static let shared = ServiceFactory()

    private var repositoryCache: [String: Any] = [:]

    func createBookRepository() -> BookRepositoryProtocol {
        if let cached = repositoryCache["BookRepository"] as? BookRepositoryProtocol {
            return cached
        }

        let repository: BookRepositoryProtocol = BookRepository()
        repositoryCache["BookRepository"] = repository
        return repository
    }

    func createBookService() -> BookServiceProtocol {
        let repository = createBookRepository()
        return BookService(repository: repository)
    }
}
```

### 테스트 환경

```swift
class MockServiceFactory: ServiceFactory {
    var mockBookRepository: BookRepositoryProtocol?

    override func createBookRepository() -> BookRepositoryProtocol {
        return mockBookRepository ?? super.createBookRepository()
    }
}

// 테스트
let factory = MockServiceFactory()
factory.mockBookRepository = MockBookRepository()

let service = factory.createBookService()
// Mock Repository 사용
```

## 관련 원칙

- **[PRIN-001](unidirectional-data-flow.md)**: 단방향 데이터 흐름
- **[PRIN-002](separation-of-concerns.md)**: 관심사의 분리

## 계약

이 원칙을 구현하는 계약:
- **[CONT-003](../contracts/service-contract.md)**: Service 계약
- **[CONT-004](../contracts/repository-contract.md)**: Repository 계약
