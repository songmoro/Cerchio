---
Contract ID: CONT-004
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Principles: [PRIN-002, PRIN-004]
---

# Repository 계약

## 계약 정의

Repository는 **데이터 접근만 담당**하며, 비즈니스 로직과 UI 로직을 구현하지 않는다.

```
Repository = CRUD Operations + Observable Streams
```

## 필수 책임 (Must)

### 1. CRUD 작업 제공

Repository는 반드시 다음을 제공해야 함:

```
Create → Read → Update → Delete (Observable 반환)
```

### 2. Observable 반환

- 모든 메서드는 Observable 반환
- Realm 변경사항 자동 전파
- 에러를 Observable로 전달
- Thread-safe 작업 보장

### 3. Protocol 구현

- Repository Protocol 정의
- Protocol 채택 및 구현
- 의존성 주입을 위한 인터페이스 제공
- 테스트 가능한 추상화

### 4. Generic Base 상속

- `BaseRepository<T: Object>` 상속
- Generic 타입 제약 활용
- 공통 CRUD 메서드 재사용
- 타입 안전성 보장

## 금지사항 (Must Not)

### 1. 비즈니스 로직 구현 금지

```
❌ 데이터 검증 (Validation)
❌ 데이터 변환 (DTO 변환은 Service가 담당)
❌ 복잡한 조건 분기
❌ 여러 Repository 조합
```

### 2. UI 로직 포함 금지

```
❌ import UIKit
❌ import SwiftUI
❌ Alert, Toast 표시
```

### 3. 다른 Repository 참조 금지

```
❌ 다른 Repository 의존성 주입
❌ 다른 Repository 메서드 호출
```

대신 Service에서 조합:
```swift
// ❌ Repository에서 다른 Repository 사용
class BookRepository {
    let quoteRepository: QuoteRepository

    func getBookWithQuotes(id: String) -> Observable<(Book, [Quote])> {
        return Observable.zip(
            getBook(id: id),
            quoteRepository.getQuotes(for: id) // 금지!
        )
    }
}

// ✅ Service에서 조합
class BookDetailService {
    let bookRepository: BookRepositoryProtocol
    let quoteRepository: QuoteRepositoryProtocol

    func getBookWithQuotes(id: String) -> Observable<BookDetail> {
        return Observable.zip(
            bookRepository.getBook(id: id),
            quoteRepository.getQuotes(for: id)
        ).map { book, quotes in
            BookDetail(book: book, quotes: quotes)
        }
    }
}
```

### 4. 복잡한 쿼리 금지

쿼리는 단순하게 유지:
```swift
// ✅ 단순한 필터링
func getBooks(by author: String) -> Observable<[RealmBook]> {
    return filterAndSort("author == %@", sortBy: "title", ascending: true, author)
}

// ❌ 복잡한 비즈니스 로직
func getFavoriteUnreadBooksWithRecentQuotes() -> Observable<[RealmBook]> {
    // 여러 조건 조합, 계산 로직 등 (Service로 이동해야 함)
}
```

## 구현 체크리스트

### 기본 구조

- [ ] `BaseRepository<T>`를 상속했는가?
- [ ] Protocol을 정의했는가? (`{Type}RepositoryProtocol`)
- [ ] Protocol을 채택하는가?
- [ ] Generic 타입이 `Object`를 상속하는가?

### CRUD 메서드

- [ ] Create (add, save) 메서드가 있는가?
- [ ] Read (get, filter) 메서드가 있는가?
- [ ] Update (update) 메서드가 있는가?
- [ ] Delete (delete) 메서드가 있는가?
- [ ] 모든 메서드가 Observable을 반환하는가?

### 에러 처리

- [ ] Realm 에러를 Observable로 전파하는가?
- [ ] Thread-safe 작업을 보장하는가?
- [ ] 트랜잭션 에러를 처리하는가?

### 쿼리 설계

- [ ] 쿼리가 단순한가? (단일 조건 또는 간단한 AND)
- [ ] 비즈니스 로직이 없는가?
- [ ] BaseRepository의 메서드를 활용하는가?

### 의존성 검증

- [ ] `import UIKit`이 없는가?
- [ ] 다른 Repository를 import하지 않는가?
- [ ] ServiceFactory를 사용하지 않는가?

### 파일 크기

- [ ] 파일 길이가 150줄 이하인가?
- [ ] Public 메서드가 10개 이하인가?
- [ ] Private 메서드가 3개 이하인가?

## 코드 검증

### 자동 검증 스크립트

```bash
# 1. UIKit import 검증
grep "import UIKit" Data/Repositories/*Repository.swift
# 결과 없어야 함

# 2. BaseRepository 상속 검증
grep "BaseRepository" Data/Repositories/*Repository.swift
# 모든 Repository가 상속해야 함

# 3. Observable 반환 검증
grep "func " Data/Repositories/*Repository.swift | grep -v "Observable"
# Public 메서드는 모두 Observable 반환해야 함

# 4. Protocol 정의 검증
grep "protocol.*RepositoryProtocol" Data/Repositories/*Repository.swift
# 모든 Repository에 Protocol 존재해야 함
```

### 수동 검증 (Code Review)

Pull Request 체크리스트:

**기본 구조**:
- [ ] Repository 파일 이름이 `{Type}Repository.swift` 형식인가?
- [ ] BaseRepository를 상속하는가?

**원칙 준수**:
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md) 준수
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md) 준수

**코드 품질**:
- [ ] CRUD 작업만 제공하는가?
- [ ] 쿼리가 단순한가?
- [ ] 다른 Repository를 참조하지 않는가?

## 준수 예시

```swift
import RxSwift
import RealmSwift

// MARK: - Protocol
protocol BookRepositoryProtocol {
    func getBook(id: String) -> Observable<RealmBook>
    func getBooks() -> Observable<[RealmBook]>
    func getBooks(by author: String) -> Observable<[RealmBook]>
    func save(_ book: RealmBook) -> Observable<RealmBook>
    func delete(id: String) -> Observable<Void>
}

// MARK: - Repository
final class BookRepository: BaseRepository<RealmBook>, BookRepositoryProtocol {

    func getBook(id: String) -> Observable<RealmBook> {
        return findById(id)
    }

    func getBooks() -> Observable<[RealmBook]> {
        return findAll(sortBy: "createdAt", ascending: false)
    }

    func getBooks(by author: String) -> Observable<[RealmBook]> {
        return filterAndSort(
            "author == %@",
            sortBy: "title",
            ascending: true,
            author
        )
    }

    func save(_ book: RealmBook) -> Observable<RealmBook> {
        return add(book)
    }

    func delete(id: String) -> Observable<Void> {
        return deleteById(id)
    }
}
```

## 위반 예시

```swift
import RxSwift
import RealmSwift
import UIKit // ❌ UI import

final class BookRepository: BaseRepository<RealmBook> {
    // ❌ 다른 Repository 의존성
    private let quoteRepository: QuoteRepository

    // ❌ 비즈니스 로직 (검증)
    func save(_ book: RealmBook) -> Observable<RealmBook> {
        guard !book.title.isEmpty else {
            return .error(ValidationError.emptyTitle)
        }

        guard book.title.count >= 2 else {
            return .error(ValidationError.titleTooShort)
        }

        // ❌ UI 로직
        showLoadingIndicator()

        return add(book)
    }

    // ❌ 복잡한 비즈니스 로직
    func getFavoriteUnreadBooks() -> Observable<[RealmBook]> {
        return Observable.create { observer in
            let realm = try! Realm()

            // ❌ 복잡한 조건 분기
            let books = realm.objects(RealmBook.self)
                .filter("isFavorite == true")
                .filter { book in
                    // ❌ 비즈니스 로직 (읽지 않은 책 계산)
                    let totalPages = book.totalPages
                    let currentPage = book.currentPage
                    return currentPage < totalPages
                }
                .sorted { $0.priority > $1.priority }

            observer.onNext(Array(books))
            observer.onCompleted()
            return Disposables.create()
        }
    }

    // ❌ 다른 Repository 조합
    func getBookWithQuotes(id: String) -> Observable<(RealmBook, [RealmQuote])> {
        return Observable.zip(
            getBook(id: id),
            quoteRepository.getQuotes(for: id) // ❌ 금지!
        )
    }

    // ❌ UI 메서드
    private func showLoadingIndicator() {
        DispatchQueue.main.async {
            // UI 로직
        }
    }
}
```

## 위반 시 수정 방법

### 문제: 비즈니스 로직 포함

**Before (위반)**:
```swift
func save(_ book: RealmBook) -> Observable<RealmBook> {
    guard !book.title.isEmpty else { // ❌ 검증 로직
        return .error(ValidationError.emptyTitle)
    }
    return add(book)
}
```

**After (계약 준수)**:
```swift
// Repository: 검증 없이 저장만
func save(_ book: RealmBook) -> Observable<RealmBook> {
    return add(book)
}

// Service: 검증 담당
func saveBook(_ book: Book) -> Observable<Book> {
    guard !book.title.isEmpty else {
        return .error(ValidationError.emptyTitle)
    }
    return repository.save(book.toRealmModel())
        .map { $0.toDTO() }
}
```

### 문제: 다른 Repository 조합

**Before (위반)**:
```swift
class BookRepository {
    let quoteRepository: QuoteRepository // ❌

    func getBookWithQuotes(id: String) -> Observable<(Book, [Quote])> {
        return Observable.zip(
            getBook(id: id),
            quoteRepository.getQuotes(for: id) // ❌
        )
    }
}
```

**After (계약 준수)**:
```swift
// Repository: 각자 단일 책임
class BookRepository {
    func getBook(id: String) -> Observable<RealmBook> {
        return findById(id)
    }
}

class QuoteRepository {
    func getQuotes(for bookId: String) -> Observable<[RealmQuote]> {
        return filterAndSort("bookId == %@", sortBy: "createdAt", ascending: true, bookId)
    }
}

// Service: 조합 담당
class BookDetailService {
    func getBookWithQuotes(id: String) -> Observable<BookDetail> {
        return Observable.zip(
            bookRepository.getBook(id: id),
            quoteRepository.getQuotes(for: id)
        ).map { book, quotes in
            BookDetail(book: book.toDTO(), quotes: quotes.map { $0.toDTO() })
        }
    }
}
```

## 관련 문서

**원칙**:
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-003](service-contract.md) - Service 계약

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md) - Feature 구현 가이드
