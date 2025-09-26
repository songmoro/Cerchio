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
- Realm Object inheritance for persistence
- Clean separation between domain models and database entities
- Type-safe relationships and queries

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

### Memory Management
- Weak coordinator references to prevent retain cycles
- Automatic coordinator cleanup on view controller dismissal
- Parent-child coordinator relationship management
- Proper dispose bag lifecycle handling

### Code Organization
- Feature-based folder structure
- Protocol-first design for testability
- Generic base classes for code reuse
- Clear separation of concerns (View/Reactor/Coordinator)
- Extension files organized by functionality

### UI Conventions
- Programmatic Auto Layout using SnapKit
- Reactive UI binding in `bind(reactor:)` methods
- Custom UI components in Common/UI/Components
- Consistent navigation patterns via coordinators

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

### Repository Implementation
- Inherit from `BaseRepository<RealmObjectType>`
- Return Observable streams for all operations
- Handle errors through reactive error handling
- Maintain protocol interfaces for dependency injection
- Use generic constraints for type-specific operations

### Extension Organization
- Group related functionality in separate extension files
- Use `// MARK:` for clear section separation
- Implement protocol conformances in dedicated extensions
- Keep extensions focused on single responsibility

### Testing Strategy
- Protocol-based dependencies for mockability
- Generic test utilities for common patterns
- Reactive test schedules for async operations
- Coordinator navigation testing via child relationship verification
- Repository testing with in-memory Realm instances

## Deployment Target

- iOS 16.0 minimum deployment target
- iPhone only (Portrait orientation)
- Korean localization with fallback to English
