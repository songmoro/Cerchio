---
Contract ID: CONT-003
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Principles: [PRIN-002, PRIN-004]
---

# Service 계약

## 계약 정의

Service는 **비즈니스 로직만 담당**하며, UI와 네비게이션을 다루지 않는다.

```
Service = Business Logic + Repository Composition
```

## 필수 책임 (Must)

### 1. Repository 조합

Service는 반드시 다음을 수행해야 함:

```
Multiple Repositories → Business Logic → Combined Result
```

### 2. 비즈니스 로직 구현

- 데이터 검증 (Validation)
- 데이터 변환 (Transformation)
- 복잡한 조건 분기
- 여러 Repository 결과 조합

### 3. DTO 변환

- Realm 객체 → DTO 변환
- DTO → Realm 객체 변환
- API 응답 → Domain Model 변환
- Domain Model → API 요청 변환

### 4. Observable 반환

- 모든 메서드는 Observable 반환
- 에러를 Observable 체인으로 전파
- 비동기 작업 조율 (flatMap, zip, concat)
- Thread 관리 (observeOn, subscribeOn)

## 금지사항 (Must Not)

### 1. UI 로직 포함 금지

```
❌ import UIKit
❌ import SwiftUI
❌ UIViewController, UIView 타입 참조
❌ Alert, Toast 표시
```

### 2. 네비게이션 수행 금지

```
❌ NavigationController 참조
❌ ViewController 생성
❌ 화면 전환 로직
```

### 3. 상태 관리 금지

```
❌ State 객체 저장
❌ Published, @State, @StateObject 사용
❌ Reactor 참조
```

대신 결과만 반환:
```swift
// ✅ Service는 결과만 반환
func saveQuote(text: String) -> Observable<Quote> {
    // 로직 수행
    return .just(quote)
}

// ❌ Service가 State 변경
func saveQuote(text: String) {
    // ...
    reactor.state.quote = quote // 금지!
}
```

### 4. ServiceFactory 저장 금지

```
❌ private let serviceFactory: ServiceFactory
```

대신 Repository만 저장:
```swift
// ✅ 필요한 Repository만 저장
private let bookRepository: BookRepositoryProtocol
private let quoteRepository: QuoteRepositoryProtocol

init(serviceFactory: ServiceFactory) {
    self.bookRepository = serviceFactory.createBookRepository()
    self.quoteRepository = serviceFactory.createQuoteRepository()
}
```

## 구현 체크리스트

### 기본 구조

- [ ] Protocol을 정의했는가? (`{Service}Protocol`)
- [ ] Protocol을 채택하는가?
- [ ] ServiceFactory를 생성자에서만 사용하는가?
- [ ] Repository를 private 프로퍼티로 저장하는가?

### 메서드 설계

- [ ] 모든 메서드가 Observable을 반환하는가?
- [ ] 메서드가 10-30줄 이내인가?
- [ ] 단일 책임을 갖는가? (하나의 작업만 수행)
- [ ] 부작용이 없는가? (같은 입력 → 같은 출력)

### DTO 변환

- [ ] Realm 객체를 직접 반환하지 않는가?
- [ ] DTO 변환 메서드가 있는가? (`toDTO()`, `toRealmModel()`)
- [ ] DTO가 struct인가? (immutable)

### 에러 처리

- [ ] 에러를 Observable로 전파하는가?
- [ ] Custom Error를 정의했는가?
- [ ] catch 연산자로 에러를 처리하는가?

### 의존성 검증

- [ ] `import UIKit`이 없는가?
- [ ] `import RealmSwift`가 없는가? (Repository가 담당)
- [ ] ServiceFactory를 저장하지 않는가?
- [ ] Protocol 기반 의존성 주입을 사용하는가?

### 파일 크기

- [ ] 파일 길이가 200줄 이하인가?
- [ ] Public 메서드가 10개 이하인가?
- [ ] Private 메서드가 5개 이하인가?

## 코드 검증

### 자동 검증 스크립트

```bash
# 1. UIKit import 검증
grep "import UIKit" Features/*/Reactor/*Service.swift
# 결과 없어야 함

# 2. RealmSwift import 검증
grep "import RealmSwift" Features/*/Reactor/*Service.swift
# 결과 없어야 함

# 3. Observable 반환 검증
grep "func " Features/*/Reactor/*Service.swift | grep -v "Observable"
# Public 메서드는 모두 Observable 반환해야 함

# 4. Protocol 정의 검증
grep "protocol.*ServiceProtocol" Features/*/Reactor/*Service.swift
# 모든 Service에 Protocol 존재해야 함
```

### 수동 검증 (Code Review)

Pull Request 체크리스트:

**기본 구조**:
- [ ] Service 파일 이름이 `{Feature}Service.swift` 형식인가?
- [ ] Protocol과 구현체가 모두 존재하는가?

**원칙 준수**:
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md) 준수
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md) 준수

**코드 품질**:
- [ ] 비즈니스 로직만 포함하는가?
- [ ] DTO 변환이 명확한가?
- [ ] Observable 체이닝이 적절한가?

## 준수 예시

```swift
import RxSwift

// MARK: - Protocol
protocol BookDetailServiceProtocol {
    func loadBookDetail(bookId: String) -> Observable<BookDetail>
    func saveQuote(bookId: String, text: String) -> Observable<Quote>
    func deletePhoto(photoId: String) -> Observable<Void>
}

// MARK: - Service
final class BookDetailService: BookDetailServiceProtocol {
    // MARK: - Properties
    private let bookRepository: BookRepositoryProtocol
    private let quoteRepository: QuoteRepositoryProtocol
    private let photoRepository: PhotoRepositoryProtocol

    // MARK: - Initialization
    init(serviceFactory: ServiceFactory) {
        self.bookRepository = serviceFactory.createBookRepository()
        self.quoteRepository = serviceFactory.createQuoteRepository()
        self.photoRepository = serviceFactory.createPhotoRepository()
    }

    // MARK: - Public Methods
    func loadBookDetail(bookId: String) -> Observable<BookDetail> {
        return Observable.zip(
            bookRepository.getBook(id: bookId),
            quoteRepository.getQuotes(for: bookId),
            photoRepository.getPhotos(for: bookId)
        )
        .map { book, quotes, photos in
            BookDetail(
                book: book.toDTO(),
                quotes: quotes.map { $0.toDTO() },
                photos: photos.map { $0.toDTO() }
            )
        }
    }

    func saveQuote(bookId: String, text: String) -> Observable<Quote> {
        // 검증
        guard validateQuote(text: text) else {
            return .error(ServiceError.invalidQuote)
        }

        // 변환
        let quote = createQuoteDTO(bookId: bookId, text: text)

        // 저장
        return quoteRepository.save(quote.toRealmModel())
            .map { $0.toDTO() }
    }

    func deletePhoto(photoId: String) -> Observable<Void> {
        return photoRepository.delete(id: photoId)
    }

    // MARK: - Private Methods
    private func validateQuote(text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count >= 10
    }

    private func createQuoteDTO(bookId: String, text: String) -> Quote {
        return Quote(
            id: UUID().uuidString,
            bookId: bookId,
            text: text,
            createdAt: Date()
        )
    }
}

// MARK: - Error
enum ServiceError: Error {
    case invalidQuote
    case notFound
}
```

## 위반 예시

```swift
import RxSwift
import UIKit // ❌ UI import
import RealmSwift // ❌ Database import

final class BookDetailService {
    // ❌ ServiceFactory 저장
    private let serviceFactory: ServiceFactory

    // ❌ Reactor 참조
    private weak var reactor: BookDetailReactor?

    // ❌ State 관리
    var isLoading: Bool = false

    // ❌ Observable 반환 안 함
    func saveQuote(text: String) {
        isLoading = true

        // ❌ UI 로직
        let alert = UIAlertController(title: "저장 중...", message: nil, preferredStyle: .alert)

        // ❌ Realm 직접 접근
        let realm = try! Realm()
        let quote = RealmQuote()
        quote.text = text

        try! realm.write {
            realm.add(quote)
        }

        // ❌ State 직접 변경
        reactor?.currentState.quote = quote.toDTO()

        // ❌ 네비게이션
        let successVC = SuccessViewController()
        navigationController?.present(successVC, animated: true)

        isLoading = false
    }

    // ❌ 너무 긴 메서드 (50줄 이상)
    func complexBusinessLogic() -> Observable<Result> {
        // 복잡한 로직 50줄...
        // 여러 Repository 호출
        // 복잡한 변환
        // 중첩된 조건문
    }
}
```

## 위반 시 수정 방법

### 문제: ServiceFactory 저장

**Before (위반)**:
```swift
class BookDetailService {
    private let serviceFactory: ServiceFactory // ❌

    func someMethod() {
        let newRepo = serviceFactory.createSomeRepository() // ❌
    }
}
```

**After (계약 준수)**:
```swift
class BookDetailService {
    private let bookRepository: BookRepositoryProtocol
    private let quoteRepository: QuoteRepositoryProtocol

    init(serviceFactory: ServiceFactory) {
        self.bookRepository = serviceFactory.createBookRepository()
        self.quoteRepository = serviceFactory.createQuoteRepository()
    }
}
```

### 문제: Observable 미반환

**Before (위반)**:
```swift
func saveQuote(text: String) { // ❌ Void 반환
    let quote = createQuote(text: text)
    repository.save(quote)
}
```

**After (계약 준수)**:
```swift
func saveQuote(text: String) -> Observable<Quote> { // ✅ Observable 반환
    let quote = createQuote(text: text)
    return repository.save(quote.toRealmModel())
        .map { $0.toDTO() }
}
```

### 문제: Realm 객체 직접 반환

**Before (위반)**:
```swift
func loadBook() -> Observable<RealmBook> { // ❌ Realm 객체
    return bookRepository.getBook(id: id)
}
```

**After (계약 준수)**:
```swift
func loadBook() -> Observable<Book> { // ✅ DTO 반환
    return bookRepository.getBook(id: id)
        .map { $0.toDTO() }
}
```

## 관련 문서

**원칙**:
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-001](reactor-contract.md) - Reactor 계약
- [CONT-004](repository-contract.md) - Repository 계약

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md) - Feature 구현 가이드
