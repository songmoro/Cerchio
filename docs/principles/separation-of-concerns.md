---
Principle ID: PRIN-002
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Documents: [PRIN-001, PRIN-005]
---

# 관심사의 분리 원칙

## 원칙 정의

각 컴포넌트는 하나의 책임만 가지며, 다른 책임과 명확히 분리된다.

```
1 Component = 1 Responsibility
```

## 문제 배경 (Why)

### 단일 컴포넌트에 여러 책임이 있을 때의 문제

**1. Massive View Controller 문제**
```swift
class BookDetailViewController {
    // UI 렌더링
    // 네트워크 호출
    // 데이터베이스 접근
    // 비즈니스 로직
    // 네비게이션
    // → 1000줄 이상, 테스트 불가능
}
```

**2. 변경 영향 범위 확대**
```
UI 변경 → 비즈니스 로직 수정 필요
데이터베이스 변경 → UI 수정 필요
→ 모든 변경이 전체 시스템에 영향
```

**3. 재사용 불가능**
```
동일한 데이터 로직을 다른 화면에서 사용 불가
→ 코드 중복 발생
```

**4. 테스트 어려움**
```
UI 테스트를 위해 Database를 모킹해야 함
비즈니스 로직 테스트를 위해 UI를 모킹해야 함
→ 테스트 복잡도 증가
```

### 관심사 분리특성

**1. 단일 책임 원칙 (Single Responsibility Principle)**
```
ViewController: UI 렌더링
Reactor: 상태 관리
Service: 비즈니스 로직
Repository: 데이터 접근
```
- 각 컴포넌트의 역할이 명확
- 변경 영향 범위가 제한적

**2. 재사용성**
```
Service를 여러 Reactor에서 사용
Repository를 여러 Service에서 사용
```

**3. 테스트 용이성**
```
Service 테스트 = Repository만 Mock
Reactor 테스트 = Service만 Mock
```

## 제약조건 (Constraints)

### 1. 계층별 책임

**Presentation Layer (UI + 상태 관리)**:
```
ViewController: UI 렌더링, 사용자 이벤트 캡처
Reactor: 상태 관리, 비동기 작업 조율
Coordinator: 네비게이션, 화면 전환
```

**Domain Layer (비즈니스 로직)**:
```
Service: 비즈니스 로직, Repository 조합
DTO: 데이터 전송 객체
```

**Data Layer (데이터 접근)**:
```
Repository: 데이터 소스 추상화
DatabaseModel: 데이터베이스 엔티티
NetworkClient: 외부 API 호출
```

**Infrastructure Layer (공통 유틸리티)**:
```
Managers: 전역 상태 관리 (Timer, Storage 등)
Extensions: 유틸리티 확장
```

### 2. 금지사항

**ViewController가 하면 안되는 것**:
- 직접 Repository 호출 (Domain 계층 건너뜀)
- 비즈니스 로직 구현 (Reactor/Service 역할)
- 다른 ViewController 생성 (Coordinator 역할)

**Reactor가 하면 안되는 것**:
- UI 로직 (ViewController 역할)
- 직접 Repository 호출 (Service 역할)
- 네비게이션 (Coordinator 역할)

**Service가 하면 안되는 것**:
- UI 로직
- 상태 관리 (Reactor 역할)
- 네비게이션

**Repository가 하면 안되는 것**:
- 비즈니스 로직 (Service 역할)
- UI 로직
- 상태 관리

## 코드 검증

### 자동 검증 (CI 가능)

**1. 파일 길이 검증**
```bash
# ViewController/Reactor 파일 길이 체크
find Features -name "*ViewController.swift" -exec wc -l {} \; | awk '$1 > 300'
find Features -name "*Reactor.swift" -exec wc -l {} \; | awk '$1 > 200'
```

**2. Import 개수 검증**
```bash
# 특정 파일의 import 개수 (너무 많으면 책임 과다)
grep "^import " MyFile.swift | wc -l
# 5개 이하가 적절
```

**3. 금지된 Import 검증**
```bash
# Reactor 파일에 UIKit import 금지
grep -r "import UIKit" Features/*/Reactor/*.swift

# Service 파일에 UIKit import 금지
grep -r "import UIKit" Features/*/Service/*.swift
```

### 수동 검증 (Code Review)

**ViewController 체크리스트**:
- [ ] UI 렌더링과 이벤트 캡처만 수행하는가?
- [ ] Repository나 Database를 직접 import하지 않는가?
- [ ] 비즈니스 로직이 없는가?
- [ ] 다른 ViewController를 직접 생성하지 않는가?

**Reactor 체크리스트**:
- [ ] 상태 관리만 수행하는가?
- [ ] `import UIKit`이 없는가?
- [ ] mutate() 메서드가 10줄 이하인가?
- [ ] 복잡한 로직은 Service로 위임했는가?

**Service 체크리스트**:
- [ ] 비즈니스 로직 구현만 하는가?
- [ ] `import UIKit`이 없는가?
- [ ] Repository만 호출하고 직접 Database 접근하지 않는가?

**Repository 체크리스트**:
- [ ] 데이터 접근만 수행하는가?
- [ ] CRUD 로직 외 비즈니스 로직이 없는가?
- [ ] Observable 반환 타입을 사용하는가?

### 준수 예시

**ViewController**:
```swift
// UI만 담당
class BookDetailViewController: BaseViewController<BookDetailReactor> {
    override func bind(reactor: BookDetailReactor) {
        // Input: UI 이벤트 → Action
        button.rx.tap
            .map { Reactor.Action.save }
            .bind(to: reactor.action)

        // Output: State → UI 업데이트
        reactor.state.map { $0.title }
            .bind(to: titleLabel.rx.text)
    }
}
```

**Reactor**:
```swift
// 상태 관리만 담당
class BookDetailReactor: Reactor {
    private let service: BookDetailService

    func mutate(action: Action) -> Observable<Mutation> {
        case .save:
            // 비즈니스 로직은 Service에 위임
            return service.saveData()
                .map { .dataSaved }
    }
}
```

**Service**:
```swift
// 비즈니스 로직만 담당
class BookDetailService {
    private let serviceFactory: ServiceFactory

    func saveData() -> Observable<Void> {
        let bookRepo = serviceFactory.createBookRepository()
        let quoteRepo = serviceFactory.createQuoteRepository()

        // 복잡한 로직 수행
        return Observable.zip(
            bookRepo.save(book),
            quoteRepo.save(quote)
        ).map { _ in () }
    }
}
```

**Repository**:
```swift
// 데이터 접근만 담당
class BookRepository: BaseRepository<RealmBook> {
    func save(_ book: RealmBook) -> Observable<RealmBook> {
        return performWriteTransaction { realm in
            realm.add(book)
            return book
        }
    }
}
```

### 위반 예시

**책임 혼재**:
```swift
// ViewController가 너무 많은 책임 수행
class BookDetailViewController {
    func saveBook() {
        // 비즈니스 로직 (Service 역할)
        let book = RealmBook()
        book.title = titleTextField.text

        // 데이터 접근 (Repository 역할)
        let realm = try! Realm()
        try! realm.write {
            realm.add(book)
        }

        // 네비게이션 (Coordinator 역할)
        let nextVC = SuccessViewController()
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
```

### 위반 시 조치

**시나리오**: ViewController에 비즈니스 로직이 있음

**잘못된 해결책**:
```swift
// 그냥 주석으로 "추후 리팩토링" 표시
// TODO: 나중에 Service로 분리
```

**올바른 해결책**:
```swift
// 1. Service 생성
class BookDetailService {
    func validateAndSave(title: String) -> Observable<Void> {
        // 비즈니스 로직을 Service로 이동
    }
}

// 2. Reactor에서 Service 호출
func mutate(action: Action) -> Observable<Mutation> {
    return service.validateAndSave(title: title)
        .map { .dataSaved }
}

// 3. ViewController는 단순화
button.rx.tap
    .map { Reactor.Action.save(title) }
    .bind(to: reactor.action)
```

## 관련 원칙

- **[PRIN-001](unidirectional-data-flow.md)**: 단방향 데이터 흐름
- **[PRIN-005](dependency-inversion.md)**: 의존성 역전

## 계약

이 원칙을 구현하는 계약:
- **[CONT-001](../contracts/reactor-contract.md)**: Reactor 계약
- **[CONT-002](../contracts/coordinator-contract.md)**: Coordinator 계약
- **[CONT-003](../contracts/service-contract.md)**: Service 계약
- **[CONT-004](../contracts/repository-contract.md)**: Repository 계약
- **[CONT-005](../contracts/view-contract.md)**: View 계약
