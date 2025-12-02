---
Contract ID: CONT-002
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Principles: [PRIN-002, PRIN-004]
---

# Coordinator 계약

## 계약 정의

Coordinator는 **네비게이션만 담당**하며, 비즈니스 로직과 UI 로직을 구현하지 않는다.

```
Coordinator = Navigation + Flow Control Only
```

## 필수 책임 (Must)

### 1. ViewController 생명주기 관리

Coordinator는 반드시 다음을 수행해야 함:

```
Create → Configure → Present → Dismiss → Release
```

### 2. Child Coordinator 관리

- Child Coordinator를 배열로 저장
- `addChildCoordinator()`로 추가
- `removeChildCoordinator()`로 제거
- View Controller dismiss 시 자동 정리

### 3. 네비게이션 흐름 제어

- `start()` 메서드로 시작점 정의
- NavigationEvent 구독 및 처리
- 화면 전환 (push, present, dismiss) 수행
- Deep Link 라우팅

### 4. ServiceFactory 전달

- ViewController 생성 시 ServiceFactory 주입
- Reactor 생성 시 필요한 Service 제공
- 의존성 주입 체인 유지

## 금지사항 (Must Not)

### 1. Repository 직접 접근 금지

```
❌ import RealmSwift
❌ Repository 생성 또는 호출
❌ Database 접근
```

### 2. 비즈니스 로직 구현 금지

```
❌ 데이터 검증
❌ 데이터 변환
❌ 복잡한 조건 분기 (네비게이션 외)
```

### 3. UI 로직 구현 금지

```
❌ UIView 설정
❌ Layout 구성
❌ 애니메이션 직접 구현
```

대신 ViewController에게 위임:
```swift
let viewController = BookDetailViewController(reactor: reactor)
viewController.configureInitialState() // VC가 UI 설정
```

### 4. Reactor 상태 직접 조작 금지

```
❌ reactor.currentState.someValue = newValue
❌ reactor.action.onNext(.someAction)
```

## 구현 체크리스트

### 기본 구조

- [ ] `BaseCoordinator`를 상속했는가?
- [ ] `start()` 메서드를 구현했는가?
- [ ] `finish()` 메서드를 구현했는가?
- [ ] `childCoordinators` 배열을 관리하는가?

### 생명주기 관리

- [ ] ViewController 생성 시 ServiceFactory를 주입하는가?
- [ ] ViewController dismiss 시 Child Coordinator를 제거하는가?
- [ ] NavigationController를 weak 참조로 저장하는가?
- [ ] Coordinator 간 순환 참조가 없는가?

### 네비게이션 처리

- [ ] NavigationEvent를 구독하는가?
- [ ] 화면 전환만 수행하는가? (로직 없음)
- [ ] 전환 결과를 Parent에게 전달하는가?
- [ ] Deep Link를 처리하는가?

### 의존성 검증

- [ ] `import RealmSwift`가 없는가?
- [ ] Repository를 직접 import하지 않는가?
- [ ] ServiceFactory를 통해서만 의존성을 전달하는가?

### 파일 크기

- [ ] 파일 길이가 150줄 이하인가?
- [ ] 메서드가 10개 이하인가?
- [ ] Child Coordinator가 5개 이하인가?

## 코드 검증

### 자동 검증 스크립트

```bash
# 1. RealmSwift import 검증
grep "import RealmSwift" Features/*/Coordinator/*Coordinator.swift
# 결과 없어야 함

# 2. Repository import 검증
grep "Repository" Features/*/Coordinator/*Coordinator.swift | grep "import"
# 결과 없어야 함

# 3. 파일 길이 검증
find Features -name "*Coordinator.swift" -exec wc -l {} \; | awk '$1 > 150 {print "Too long: " $2}'

# 4. start() 메서드 존재 검증
grep "func start()" Features/*/Coordinator/*Coordinator.swift
# 모든 Coordinator에 존재해야 함
```

### 수동 검증 (Code Review)

Pull Request 체크리스트:

**기본 구조**:
- [ ] Coordinator 파일 이름이 `{Feature}Coordinator.swift` 형식인가?
- [ ] BaseCoordinator를 상속하는가?

**원칙 준수**:
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md) 준수
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md) 준수

**코드 품질**:
- [ ] 네비게이션 로직만 포함하는가?
- [ ] Child Coordinator를 올바르게 관리하는가?
- [ ] 메모리 누수가 없는가? (weak self, weak 참조)

## 준수 예시

```swift
import UIKit
import RxSwift

final class BookDetailCoordinator: BaseCoordinator {
    // MARK: - Properties
    private weak var navigationController: UINavigationController?
    private let serviceFactory: ServiceFactory
    private let bookId: String
    private let disposeBag = DisposeBag()

    // MARK: - Initialization
    init(
        navigationController: UINavigationController?,
        serviceFactory: ServiceFactory,
        bookId: String
    ) {
        self.navigationController = navigationController
        self.serviceFactory = serviceFactory
        self.bookId = bookId
    }

    // MARK: - Start
    func start() {
        let service = BookDetailService(serviceFactory: serviceFactory)
        let reactor = BookDetailReactor(service: service, bookId: bookId)
        let viewController = BookDetailViewController(reactor: reactor)

        // NavigationEvent 구독
        reactor.navigationEvents
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigation(event)
            })
            .disposed(by: disposeBag)

        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: - Navigation
    private func handleNavigation(_ event: BookDetailReactor.NavigationEvent) {
        switch event {
        case .showQuoteSave:
            showQuoteSave()

        case .showPhotoViewer(let photoId):
            showPhotoViewer(photoId: photoId)
        }
    }

    private func showQuoteSave() {
        let coordinator = QuoteSaveCoordinator(
            navigationController: navigationController,
            serviceFactory: serviceFactory,
            bookId: bookId
        )
        addChildCoordinator(coordinator)
        coordinator.start()
    }

    private func showPhotoViewer(photoId: String) {
        let coordinator = PhotoViewerCoordinator(
            navigationController: navigationController,
            serviceFactory: serviceFactory,
            photoId: photoId
        )
        addChildCoordinator(coordinator)
        coordinator.start()
    }
}
```

## 위반 예시

```swift
import UIKit
import RxSwift
import RealmSwift // ❌ Database import

final class BookDetailCoordinator: BaseCoordinator {
    // ❌ Repository 직접 참조
    private let bookRepository: BookRepository

    func start() {
        // ❌ 비즈니스 로직 (데이터 검증)
        guard let book = try? bookRepository.getBook(id: bookId) else {
            showErrorAlert()
            return
        }

        // ❌ 데이터 변환 로직
        let displayTitle = book.title.isEmpty ? "제목 없음" : book.title
        let formattedAuthor = book.author.components(separatedBy: ",").joined(separator: " · ")

        // ❌ UI 로직 (View Controller가 해야 함)
        let viewController = BookDetailViewController(reactor: reactor)
        viewController.view.backgroundColor = .systemBackground
        viewController.titleLabel.text = displayTitle
        viewController.authorLabel.text = formattedAuthor

        navigationController?.pushViewController(viewController, animated: true)
    }

    // ❌ Reactor 상태 직접 조작
    private func refreshData() {
        let book = try? bookRepository.getBook(id: bookId)
        reactor.currentState.book = book
    }

    // ❌ UI 애니메이션 구현
    private func showErrorAlert() {
        let alert = UIAlertController(title: "오류", message: "책을 찾을 수 없습니다", preferredStyle: .alert)
        UIView.animate(withDuration: 0.3) {
            // 애니메이션 로직
        }
    }
}
```

## 위반 시 수정 방법

### 문제: Repository 직접 접근

**Before (위반)**:
```swift
class BookDetailCoordinator {
    let repository: BookRepository

    func start() {
        guard let book = repository.getBook(id: id) else { return }
        // ...
    }
}
```

**After (계약 준수)**:
```swift
class BookDetailCoordinator {
    func start() {
        // Service는 Reactor에 주입
        let service = BookDetailService(serviceFactory: serviceFactory)
        let reactor = BookDetailReactor(service: service, bookId: bookId)
        let viewController = BookDetailViewController(reactor: reactor)

        navigationController?.pushViewController(viewController, animated: true)
    }
}
```

### 문제: UI 로직 구현

**Before (위반)**:
```swift
func start() {
    let vc = BookDetailViewController(reactor: reactor)
    vc.view.backgroundColor = .white
    vc.titleLabel.text = "제목"
    // UI 설정은 ViewController가 해야 함
}
```

**After (계약 준수)**:
```swift
func start() {
    // ViewController가 UI 설정을 담당
    let vc = BookDetailViewController(reactor: reactor)
    navigationController?.pushViewController(vc, animated: true)
}
```

## 관련 문서

**원칙**:
- [PRIN-002](../principles/separation-of-concerns.md) - 관심사의 분리
- [PRIN-004](../principles/reactive-programming.md) - 반응형 프로그래밍

**계약**:
- [CONT-001](reactor-contract.md) - Reactor 계약
- [CONT-005](view-contract.md) - View 계약

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md) - Feature 구현 가이드
