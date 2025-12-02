---
Guide ID: GUIDE-004
Version: 1.0.0
Last Updated: 2025-12-02
Related Principles: [PRIN-002]
---

# 테스팅 전략

계층별 테스트 전략과 작성 방법을 설명합니다.

## 테스트 피라미드

```
        /\
       /  \  E2E Tests (소수)
      /────\
     /      \ Integration Tests (중간)
    /────────\
   /          \ Unit Tests (다수)
  /────────────\
```

## 계층별 테스트 전략

### 1. Repository 테스트

**목적**: 데이터 접근 로직 검증

**특징**:
- In-memory Realm 사용
- 실제 Database 로직 테스트
- Mock 최소화

**예시**:
```swift
import XCTest
import RxSwift
import RealmSwift
@testable import Cerchio

final class BookRepositoryTests: XCTestCase {
    var repository: BookRepository!
    var disposeBag: DisposeBag!
    var realm: Realm!

    override func setUp() {
        super.setUp()

        // In-memory Realm 설정
        var config = Realm.Configuration.defaultConfiguration
        config.inMemoryIdentifier = "test-realm"
        realm = try! Realm(configuration: config)

        repository = BookRepository()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        try? realm.write {
            realm.deleteAll()
        }
        super.tearDown()
    }

    func testSaveBook() {
        // Given
        let book = RealmBook()
        book.id = "test-id"
        book.title = "Test Book"

        // When
        let expectation = XCTestExpectation(description: "Save book")
        var savedBook: RealmBook?

        repository.save(book)
            .subscribe(onNext: { book in
                savedBook = book
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(savedBook)
        XCTAssertEqual(savedBook?.id, "test-id")
        XCTAssertEqual(savedBook?.title, "Test Book")
    }
}
```

**체크리스트**:
- [ ] In-memory Realm 사용
- [ ] tearDown에서 데이터 정리
- [ ] CRUD 작업 모두 테스트
- [ ] 에러 케이스 테스트

### 2. Service 테스트

**목적**: 비즈니스 로직 검증

**특징**:
- Mock Repository 사용
- Observable 체이닝 검증
- DTO 변환 검증

**예시**:
```swift
import XCTest
import RxSwift
@testable import Cerchio

final class BookDetailServiceTests: XCTestCase {
    var service: BookDetailService!
    var mockBookRepository: MockBookRepository!
    var mockQuoteRepository: MockQuoteRepository!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        mockBookRepository = MockBookRepository()
        mockQuoteRepository = MockQuoteRepository()
        service = BookDetailService(
            bookRepository: mockBookRepository,
            quoteRepository: mockQuoteRepository
        )
        disposeBag = DisposeBag()
    }

    func testLoadBookDetail() {
        // Given
        let book = createMockRealmBook()
        let quotes = [createMockRealmQuote()]

        mockBookRepository.getBookResult = .just(book)
        mockQuoteRepository.getQuotesResult = .just(quotes)

        // When
        let expectation = XCTestExpectation(description: "Load book detail")
        var result: BookDetail?

        service.loadBookDetail(bookId: "test-id")
            .subscribe(onNext: { bookDetail in
                result = bookDetail
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.book.id, "test-id")
        XCTAssertEqual(result?.quotes.count, 1)
    }
}
```

**Mock Repository**:
```swift
final class MockBookRepository: BookRepositoryProtocol {
    var getBookResult: Observable<RealmBook> = .empty()
    var saveResult: Observable<RealmBook> = .empty()

    func getBook(id: String) -> Observable<RealmBook> {
        return getBookResult
    }

    func save(_ book: RealmBook) -> Observable<RealmBook> {
        return saveResult
    }
}
```

**체크리스트**:
- [ ] Mock Repository 생성
- [ ] 비즈니스 로직 검증
- [ ] Observable 체이닝 검증
- [ ] DTO 변환 검증
- [ ] 에러 처리 검증

### 3. Reactor 테스트

**목적**: 상태 관리 로직 검증

**특징**:
- Mock Service 사용
- RxTest 활용
- Action → State 변화 검증

**예시**:
```swift
import XCTest
import RxSwift
import RxTest
import ReactorKit
@testable import Cerchio

final class BookDetailReactorTests: XCTestCase {
    var reactor: BookDetailReactor!
    var mockService: MockBookDetailService!
    var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()

        mockService = MockBookDetailService()
        reactor = BookDetailReactor(service: mockService, bookId: "test-id")
        scheduler = TestScheduler(initialClock: 0)
    }

    func testLoadAction() {
        // Given
        let bookDetail = createMockBookDetail()
        mockService.loadBookDetailResult = .just(bookDetail)

        // When
        scheduler.createColdObservable([
            .next(100, Reactor.Action.load)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        let res = scheduler.start {
            self.reactor.state.map { $0.bookDetail }
        }

        // Then
        XCTAssertEqual(res.events.count, 2)
        XCTAssertEqual(res.events[0].value.element??.book.id, "test-id")
    }

    func testLoadingState() {
        // Given
        mockService.loadBookDetailResult = .just(createMockBookDetail())

        // When
        scheduler.createColdObservable([
            .next(100, Reactor.Action.load)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        let res = scheduler.start {
            self.reactor.state.map { $0.isLoading }
        }

        // Then
        XCTAssertEqual(res.events.count, 3)
        XCTAssertEqual(res.events[0].value.element, false) // Initial
        XCTAssertEqual(res.events[1].value.element, true)  // Loading
        XCTAssertEqual(res.events[2].value.element, false) // Loaded
    }
}
```

**Mock Service**:
```swift
final class MockBookDetailService: BookDetailServiceProtocol {
    var loadBookDetailResult: Observable<BookDetail> = .empty()

    func loadBookDetail(bookId: String) -> Observable<BookDetail> {
        return loadBookDetailResult
    }
}
```

**체크리스트**:
- [ ] Mock Service 생성
- [ ] TestScheduler 사용
- [ ] State 변화 검증
- [ ] Loading 상태 검증
- [ ] Error 상태 검증

### 4. ViewController 테스트

**목적**: View-Reactor 바인딩 검증

**특징**:
- 실제 ViewController 인스턴스 사용
- UI 이벤트 시뮬레이션
- State → UI 반영 검증

**예시**:
```swift
import XCTest
import RxSwift
@testable import Cerchio

final class BookDetailViewControllerTests: XCTestCase {
    var viewController: BookDetailViewController!
    var mockReactor: MockBookDetailReactor!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        mockReactor = MockBookDetailReactor()
        viewController = BookDetailViewController(reactor: mockReactor)
        disposeBag = DisposeBag()

        // Load view
        _ = viewController.view
    }

    func testTitleLabel() {
        // Given
        let book = Book(id: "1", title: "Test Book")
        mockReactor.currentState.bookDetail = BookDetail(book: book, quotes: [])

        // When
        viewController.reactor = mockReactor

        // Then
        XCTAssertEqual(viewController.titleLabel.text, "Test Book")
    }
}
```

**체크리스트**:
- [ ] View 로드 확인 (`_ = viewController.view`)
- [ ] State → UI 반영 검증
- [ ] Button tap 시뮬레이션

### 5. Coordinator 테스트

**목적**: 네비게이션 흐름 검증

**특징**:
- Mock NavigationController
- Child Coordinator 관리 검증
- ViewController 생성 검증

**예시**:
```swift
import XCTest
@testable import Cerchio

final class BookDetailCoordinatorTests: XCTestCase {
    var coordinator: BookDetailCoordinator!
    var mockNavigationController: UINavigationController!
    var mockServiceFactory: MockServiceFactory!

    override func setUp() {
        super.setUp()

        mockNavigationController = UINavigationController()
        mockServiceFactory = MockServiceFactory()
        coordinator = BookDetailCoordinator(
            navigationController: mockNavigationController,
            serviceFactory: mockServiceFactory,
            bookId: "test-id"
        )
    }

    func testStart() {
        // When
        coordinator.start()

        // Then
        XCTAssertEqual(mockNavigationController.viewControllers.count, 1)
        XCTAssertTrue(mockNavigationController.topViewController is BookDetailViewController)
    }

    func testChildCoordinatorAdded() {
        // When
        coordinator.showQuoteSave()

        // Then
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        XCTAssertTrue(coordinator.childCoordinators.first is QuoteSaveCoordinator)
    }
}
```

**체크리스트**:
- [ ] start() 호출 시 ViewController push 확인
- [ ] Child Coordinator 추가 확인
- [ ] NavigationEvent 처리 확인

## Mock 객체 생성 패턴

### Protocol 기반 Mock

```swift
protocol BookRepositoryProtocol {
    func getBook(id: String) -> Observable<RealmBook>
}

final class MockBookRepository: BookRepositoryProtocol {
    var getBookResult: Observable<RealmBook> = .empty()
    var getBookCallCount = 0
    var getBookLastId: String?

    func getBook(id: String) -> Observable<RealmBook> {
        getBookCallCount += 1
        getBookLastId = id
        return getBookResult
    }
}
```

### Mock 헬퍼

```swift
extension MockBookRepository {
    func setupSuccess(with book: RealmBook) {
        getBookResult = .just(book)
    }

    func setupError(_ error: Error) {
        getBookResult = .error(error)
    }

    func setupEmpty() {
        getBookResult = .empty()
    }
}

// 테스트에서
mockRepository.setupSuccess(with: mockBook)
```

## 테스트 데이터 생성

### Factory Pattern

```swift
struct TestDataFactory {
    static func createBook(
        id: String = "test-id",
        title: String = "Test Book"
    ) -> RealmBook {
        let book = RealmBook()
        book.id = id
        book.title = title
        return book
    }

    static func createBookDTO(
        id: String = "test-id",
        title: String = "Test Book"
    ) -> Book {
        return Book(id: id, title: title)
    }
}

// 테스트에서
let book = TestDataFactory.createBook()
let customBook = TestDataFactory.createBook(title: "Custom Title")
```

## 비동기 테스트

### XCTestExpectation

```swift
func testAsyncOperation() {
    // Given
    let expectation = XCTestExpectation(description: "Load data")

    // When
    service.loadData()
        .subscribe(onNext: { data in
            // Then
            XCTAssertNotNil(data)
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

    wait(for: [expectation], timeout: 1.0)
}
```

### RxBlocking

```swift
import RxBlocking

func testSyncOperation() throws {
    // When
    let result = try service.loadData()
        .toBlocking()
        .first()

    // Then
    XCTAssertNotNil(result)
}
```

## 체크리스트

### 전체 테스트

- [ ] Repository 테스트 작성
- [ ] Service 테스트 작성
- [ ] Reactor 테스트 작성
- [ ] Mock 객체 생성
- [ ] Test Data Factory 생성

### 개별 테스트

- [ ] Given-When-Then 구조
- [ ] 명확한 테스트 이름
- [ ] 하나의 테스트 = 하나의 검증
- [ ] setUp/tearDown 정리

### Coverage

- [ ] Happy Path 테스트
- [ ] Error Case 테스트
- [ ] Edge Case 테스트
- [ ] Code Coverage > 80%

## 관련 문서

**원칙**:
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리

**가이드**:
- [GUIDE-001](feature-implementation.md) - Feature 구현 가이드
