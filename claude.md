# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cerchio is an iOS book management application built with Swift and UIKit. The app focuses on providing a clean, reactive architecture for book cataloging, reading tracking, and personal library management.

## Architecture

### Core Pattern: MVVM-C + ReactorKit

**MVVM-C (Model-View-ViewModel-Coordinator)**
- **Model**: Realm objects for data persistence
- **View**: UIViewController + UIView components
- **ViewModel**: ReactorKit Reactors for state management
- **Coordinator**: Navigation and flow control

**ReactorKit Integration**
- Unidirectional data flow architecture
- State-driven UI updates
- Action-Mutation-State cycle
- Combined with RxSwift for reactive streams

**Base Classes Structure**
- `BaseCoordinator`: Foundation for all coordinators
- `BaseViewController<T: Reactor>`: Generic base for reactive view controllers
- `BaseRepository<T: Object>`: Generic Realm data access layer

### Navigation Architecture

**Coordinator Pattern**
- Hierarchical coordinator tree
- Parent-child coordinator relationships
- Automatic memory management via `viewDidDisappear`
- Reactive navigation events using `PublishRelay<NavigationEvent>`

**Flow Management**
```
AppCoordinator (window management)
  └── MainTabBarController (custom circular tab bar)
      ├── Feature Coordinators (Library, Search, Settings...)
      │   └── Sub-feature Coordinators (BookDetail, QuoteSave...)
```

### Data Layer

**Repository Pattern**
- Protocol-based repository interfaces
- Generic base repository with Realm integration
- Reactive data access using RxSwift Observable streams
- Automatic error handling and state management

**Models**
- Realm Object inheritance for persistence (`RealmBook`, `RealmQuote`, `RealmPhoto`, `RealmTag`)
- Clean separation between domain models and database entities
- Type-safe relationships and queries
- Conversion methods: `toModel()` for Realm to domain, `toRealmModel()` for domain to Realm

**ServiceFactory Pattern**
- Centralized dependency injection via `ServiceFactory`
- Repository creation methods: `createBookRepository()`, `createQuoteRepository()`, `createPhotoRepository()`, `createTagRepository()`
- Service caching for performance optimization
- Environment-based factory configuration (development, staging, production, testing)

## Dependencies (Swift Package Manager)

- **SnapKit**: Auto Layout DSL for programmatic UI
- **ReactorKit**: Unidirectional reactive architecture
- **RxSwift/RxCocoa**: Reactive programming framework
- **RealmSwift**: Local database and object persistence
- **Kingfisher**: Async image loading and caching

## File Structure

```
Cerchio/
├── Application/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppCoordinator.swift
├── Common/
│   ├── Base/
│   │   ├── BaseCoordinator.swift
│   │   ├── BaseViewController.swift
│   │   └── BaseRepository.swift
│   ├── Extensions/
│   ├── Protocols/
│   └── UI/Components/
├── Data/
│   ├── Models/ (Realm objects)
│   ├── Repositories/
│   └── Network/
├── Features/
│   └── {FeatureName}/
│       ├── Coordinator/
│       ├── View/
│       └── Reactor/
└── Resources/
```

## Key Implementation Principles

### Protocol-Oriented Design Philosophy
- **Protocol-First Approach**: Define behavior contracts before implementation
- **Extension-Based Implementation**: Default implementations via protocol extensions
- **Generic Abstractions**: Type-safe, reusable components using generics
- **Composition over Inheritance**: Favor protocol conformance over class hierarchies

### Abstraction Strategy
- **Progressive Abstraction**: Start concrete, abstract when patterns emerge
- **YAGNI Compliance**: Avoid premature abstraction until actual need arises
- **Bounded Complexity**: Limit generic nesting to 2-3 levels maximum
- **Clear Documentation**: Every protocol must define purpose and extension points

### Reactive Patterns
- All data flows through Observable streams
- UI state managed via Reactor pattern
- Navigation events communicated reactively
- Automatic dispose bag management in base classes

**RxSwift Best Practices**:
- **Use Driver for UI binding**: Convert state observables to Driver for main thread guarantee and no errors
  ```swift
  // Preferred
  reactor.state.map { $0.title }
      .asDriver(onErrorJustReturn: "")
      .drive(titleLabel.rx.text)
      .disposed(by: disposeBag)

  // Avoid
  reactor.state.map { $0.title }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] title in
          self?.titleLabel.text = title
      })
      .disposed(by: disposeBag)
  ```

- **Use bind(to:) for direct bindings**: More concise than subscribe
  ```swift
  // Preferred
  button.rx.tap
      .map { MyAction.buttonTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

  // Avoid
  button.rx.tap
      .subscribe(onNext: { [weak self] in
          self?.reactor?.action.onNext(.buttonTapped)
      })
      .disposed(by: disposeBag)
  ```

- **Use flatMap for dependent async operations**: Chain operations properly
- **Share replays when needed**: Use `.share(replay: 1)` for expensive operations
- **Always use `[weak self]`**: Prevent retain cycles in closures
- **Always call `.disposed(by: disposeBag)`**: Prevent memory leaks

### Memory Management
- **Weak References**: Use `[weak self]` in all closures and callbacks to prevent retain cycles
- **Coordinator Lifecycle**: Automatic coordinator cleanup on view controller dismissal
- **Parent-Child Relationships**: Child coordinators are stored in parent and automatically released
- **DisposeBag Management**: Proper dispose bag lifecycle handling in base classes
- **Callback Cleanup**: Set callbacks to `nil` when view controllers/cells are deallocated
- **Observable Chains**: Use `.disposed(by: disposeBag)` on all RxSwift subscriptions
- The architecture is designed to prevent memory leaks through proper reference management

### Code Organization
- Feature-based folder structure
- Protocol-first design for testability
- Generic base classes for code reuse
- Clear separation of concerns (View/Reactor/Coordinator)
- Extension files organized by functionality

**Common Patterns Across Features**
- **Tag System**: User-defined tags stored per book, parsed from `#tag` format
- **Photo Management**: Local image storage with Realm metadata references
- **Quote Collection**: Text quotes with optional page numbers and notes
- **ServiceFactory Injection**: Pass `serviceFactory` to view controllers for repository access
- **Coordinator Result Patterns**: Use `PublishRelay<Result>` for coordinator completion events

### UI Conventions

**Auto Layout**
- **Always use SnapKit**: Never use NSLayoutConstraint directly
  ```swift
  // Preferred
  view.snp.makeConstraints {
      $0.edges.equalToSuperview()
  }

  // Avoid
  view.translatesAutoresizingMaskIntoConstraints = false
  NSLayoutConstraint.activate([...])
  ```

**Button Configuration (iOS 15+)**
- **Use UIButton.Configuration**: Modern, declarative button styling
  ```swift
  // Preferred
  var config = UIButton.Configuration.filled()
  config.title = "Submit"
  config.image = UIImage(systemName: "checkmark")
  config.imagePadding = 8
  button.configuration = config

  // Avoid
  button.setTitle("Submit", for: .normal)
  button.setImage(UIImage(systemName: "checkmark"), for: .normal)
  ```

**Cell Configuration (iOS 14+)**
- **Use UIContentConfiguration**: For list cells and content views
  ```swift
  // Preferred
  var config = cell.defaultContentConfiguration()
  config.text = book.title
  config.secondaryText = book.author
  config.image = bookImage
  cell.contentConfiguration = config

  // Avoid
  cell.textLabel?.text = book.title
  cell.detailTextLabel?.text = book.author
  ```

**Typography**
- **Use Custom Font System**: Never use `.systemFont()` directly
  ```swift
  // Preferred
  label.font = .customFont(.body)
  titleLabel.font = .customFont(.title, weight: .bold)

  // Avoid
  label.font = .systemFont(ofSize: 16)
  titleLabel.font = .boldSystemFont(ofSize: 24)
  ```

**General UI Guidelines**
- Reactive UI binding in `bind(reactor:)` methods
- Custom UI components in Common/UI/Components
- Consistent navigation patterns via coordinators
- **No Emojis**: Do not use emojis in code, comments, UI text, or commit messages unless explicitly requested by the user

### Development Guidelines

### Protocol-Oriented Implementation
- **Protocol Definition**: Define clear contracts with minimal required methods
- **Default Extensions**: Provide common behavior via protocol extensions
- **Generic Constraints**: Use `where` clauses for type safety and flexibility
- **Composition Patterns**: Combine protocols rather than deep inheritance chains

Example Pattern:
```swift
protocol Coordinatable: AnyObject {
    associatedtype Dependencies
    func start(with dependencies: Dependencies)
}

extension Coordinatable where Dependencies == Void {
    func start() { start(with: ()) }
}
```

### Coordinator Implementation
- Inherit from `BaseCoordinator`
- Implement required `start()` method
- Use `addChildCoordinator()` for child management
- Handle completion via `finish()` calls
- Define coordinator protocols for testability

### View Controller Implementation
- Inherit from `BaseViewController<ReactorType>`
- Implement `setupUI()` for view hierarchy
- Implement `bind(reactor:)` for reactive binding
- Use `navigationEvents` relay for navigation actions
- Create view protocols for complex components

**Modern Data Loading Pattern with Driver**
```swift
// Preferred: Use Driver for UI updates
reactor.state
    .map { $0.bookDetail }
    .compactMap { $0 }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: nil)
    .compactMap { $0 }
    .drive(onNext: { [weak self] bookDetail in
        self?.updateSnapshot(with: bookDetail)
    })
    .disposed(by: disposeBag)
```

**Callback Patterns**
- **Simple callbacks**: Use closures for one-off events (e.g., cell taps)
  ```swift
  cell.onTapped = { [weak self] in
      self?.handleCellAction()
  }
  ```

- **Coordinator communication**: Use `PublishRelay` for multi-subscriber events
  ```swift
  private let resultRelay = PublishRelay<Result>()
  var result: Observable<Result> { resultRelay.asObservable() }
  ```

- **ViewController data passing**: Use `PublishRelay` or `BehaviorRelay`
  ```swift
  let selectedItem = PublishRelay<Item>()
  // Subscribe in parent
  childVC.selectedItem
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  ```

### Reactor Service Layer Pattern

**Separate business logic from Reactor**:
- Create dedicated Service classes in the Feature/Reactor folder
- Keep Reactors focused on state management only
- Services handle complex Observable operations

**File Structure**:
```
Features/
  BookDetail/
    Reactor/
      BookDetailReactor.swift       // State management only
      BookDetailService.swift        // Business logic & data operations
```

**Service Implementation**:
```swift
// BookDetailService.swift
final class BookDetailService {
    private let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    func loadPhotos(bookId: String) -> Observable<[Photo]> {
        return Observable.create { observer in
            // Realm operations here
            observer.onNext(photos)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

// BookDetailReactor.swift
final class BookDetailReactor: Reactor {
    private let service: BookDetailService

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadPhotos:
            return service.loadPhotos(bookId: currentState.bookId)
                .map { .setPhotos($0) }
        }
    }
}
```

### Repository Implementation
- Inherit from `BaseRepository<RealmObjectType>`
- Return Observable streams for all operations
- Handle errors through reactive error handling
- Maintain protocol interfaces for dependency injection
- Use generic constraints for type-specific operations

**Common Repository Patterns**
```swift
protocol TagRepositoryProtocol {
    func getTags(for bookId: String) -> Observable<[RealmTag]>
    func saveTags(_ tags: [RealmTag]) -> Observable<[RealmTag]>
    func deleteTags(for bookId: String) -> Observable<Void>
}

final class TagRepository: BaseRepository<RealmTag>, TagRepositoryProtocol {
    func getTags(for bookId: String) -> Observable<[RealmTag]> {
        return filterAndSort("bookId == %@", sortBy: "createdAt", ascending: true, bookId)
    }
}
```

### Extension Organization
- Group related functionality in separate extension files
- Use `// MARK:` for clear section separation
- Implement protocol conformances in dedicated extensions
- Keep extensions focused on single responsibility

### Concurrency Patterns

**Use Swift Concurrency over GCD**:
- iOS 16.0+ deployment target supports async/await
- Prefer structured concurrency for better safety and readability

**Image Loading Pattern**:
```swift
// Preferred: Swift Concurrency
func loadImages(from paths: [String]) async -> [UIImage] {
    await withTaskGroup(of: UIImage?.self) { group in
        for path in paths {
            group.addTask {
                ImageStorageManager.shared.loadImage(fromPath: path)
            }
        }

        var images: [UIImage] = []
        for await image in group {
            if let image = image {
                images.append(image)
            }
        }
        return images
    }
}

// Usage in ViewController
Task {
    let images = await loadImages(from: imagePaths)
    await MainActor.run {
        updateUI(with: images)
    }
}
```

**Realm Operations**:
- **Always on main thread**: Realm objects are thread-confined
- Extract data (like image paths) before async operations
- Never access Realm objects inside Task/DispatchQueue closures

```swift
// Correct pattern
let realm = try Realm()
let photos = realm.objects(RealmPhoto.self)
let imagePaths = photos.map { $0.localImagePath } // Extract on main thread

Task {
    let images = await loadImages(from: imagePaths) // Use extracted data
    await MainActor.run {
        updateSnapshot(with: images)
    }
}
```

### Testing Strategy
- Protocol-based dependencies for mockability
- Generic test utilities for common patterns
- Reactive test schedules for async operations
- Coordinator navigation testing via child relationship verification
- Repository testing with in-memory Realm instances

## Localization

**Type-Safe Localization System**

The project uses a custom type-safe localization system to prevent runtime errors from typos in localization keys.

**Localization Files**:
- `Localizable.xcstrings`: String catalog for localized strings (ko/en)
- `Localized.swift`: Enum for simple localized strings (no arguments)
- `ArgumentLocalized.swift`: Enum for localized strings with format arguments
- `String+Localized.swift`: Extension providing type-safe localization initializers

**Usage Patterns**:

```swift
// Simple localization (no arguments)
enum Localized: String {
    case `action.save`
    case `tab.library`
}

let text = String(localized: .action.save)  // Returns "저장" (ko) or "Save" (en)

// Localization with arguments
enum ArgumentLocalized: String {
    case `timer.minutes_format`  // "%lld분" or "%lld min"
}

let text = String(localized: .timer.minutes_format, args: [25])  // Returns "25분" or "25 min"
```

**Adding New Localized Strings**:
1. Add the key to `Localizable.xcstrings` with translations
2. Add corresponding case to `Localized` or `ArgumentLocalized` enum
3. Use type-safe String initializer in code

**Benefits**:
- Compile-time checking for localization keys
- No runtime crashes from typos
- Autocomplete support in Xcode
- Centralized string management

## Deployment Target

- iOS 16.0 minimum deployment target
- iPhone only (Portrait orientation)
- Korean localization with fallback to English

## Build and Testing

### Building the Project

**Quick Compilation Check**
- Use xcodebuild only for detecting and fixing compilation errors
- Avoid full builds when possible to save time
- Focus on targeted error detection and resolution

**Build Commands**
```bash
# Quick syntax/compilation check (preferred)
xcodebuild -scheme Cerchio -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' build -configuration Debug -skipPackagePluginValidation -quiet 2>&1 | grep -E "error:"

# Standard build with iPhone 16 Pro iOS 18.5 simulator
xcodebuild -scheme Cerchio -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' clean build

# Generic iOS Simulator build (if specific device unavailable)
xcodebuild -scheme Cerchio -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

**Build Strategy**
- Use builds primarily to catch compilation errors early
- Run quick checks after significant code changes
- Full builds should be minimal and targeted
- Simulator target: iPhone 16 Pro with iOS 18.5 (default)

### Testing Approach
- Protocol-based mocking for unit tests
- Repository tests use in-memory Realm instances
- Coordinator tests verify navigation flows
- Reactor tests validate state transformations
